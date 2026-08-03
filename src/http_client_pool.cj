package linderHttp


/**
 * HTTP客户端连接池
 *
 * 自适应动态连接池：按 hostName 分组，每个 host 维护一组可复用的底层 Client。
 * - 复用积极：同 host 空闲 Client 优先复用，小批量请求不新建；
 * - 并行不串行：并发时无空闲则新建 Client，各请求独立并行；
 * - 数量自适应：Client 总数随并发自动扩展，空闲后由 release 修剪回落至 capacity。
 *
 * 由于底层 Client 的 TLS 配置（含 SNI serverName）在构建后不可变，
 * 不同 host 使用各自独立的 Client 组，保证 TLS SNI 正确。
 *
 * 请求级参数（url/method/header/body）每次通过 PooledRequest 传入，池无状态污染。
 *
 * 使用示例：
 * ```cangjie
 * let pool = LinderHttpClientPool(capacity: 8)
 * let response = pool.request()
 *     .setUrl("https://api.example.com/data")
 *     .setHeader("Authorization", "Bearer token")
 *     .send()
 * pool.destroy()
 * ```
 */
public class LinderHttpClientPool {
    private let mutex: Mutex = Mutex()
    private let cond: Condition
    private let idleClients: HashMap<String, ArrayList<Client>> = HashMap<String, ArrayList<Client>>()
    private let totalClients: HashMap<String, Int64> = HashMap<String, Int64>()
    private let poolCapacity: Int64
    private let tlsConfig: TlsClientConfig
    private let autoRedirect: Bool
    private let readTimeout: Duration
    private let writeTimeout: Duration
    private let initialWindowSize: UInt32
    private let enablePush: Bool
    private let headerTableSize: UInt32
    private let httpProxy: String
    private let httpsProxy: String

    public init(
        capacity!: Int64,
        tlsConfig!: ?TlsClientConfig = None,
        autoRedirect!: Bool = true,
        readTimeout!: Duration = Duration.second * 15,
        writeTimeout!: Duration = Duration.second * 15,
        initialWindowSize!: UInt32 = 65535,
        enablePush!: Bool = true,
        headerTableSize!: UInt32 = 4096,
        httpProxy!: String = '',
        httpsProxy!: String = ''
    ) {
        this.poolCapacity = capacity
        this.tlsConfig = if (!tlsConfig.isNone()) {
            tlsConfig.getOrThrow()
        } else {
            defaultTlsConfig()
        }
        this.autoRedirect = autoRedirect
        this.readTimeout = readTimeout
        this.writeTimeout = writeTimeout
        this.initialWindowSize = initialWindowSize
        this.enablePush = enablePush
        this.headerTableSize = headerTableSize
        this.httpProxy = httpProxy
        this.httpsProxy = httpsProxy
        synchronized(mutex) {
            cond = mutex.condition()
        }
    }

    /**
     * 复制 TLS 配置并设置目标 hostName（SNI）
     * 每个 Client 持有独立副本，避免多个 Client 共享同一 TlsClientConfig
     */
    private func copyTlsConfig(src: TlsClientConfig, hostName: String): TlsClientConfig {
        var t = TlsClientConfig()
        t.verifyMode = src.verifyMode
        if (!src.certificate.isNone()) {
            t.certificate = src.certificate
        }
        t.securityLevel = src.securityLevel

        t.supportedVersions = src.supportedVersions
        if (!src.signatureAlgorithms.isNone()) {
            t.signatureAlgorithms = src.signatureAlgorithms
        }
        t.supportedCipherSuites = src.supportedCipherSuites
        t.supportedAlpnProtocols = src.supportedAlpnProtocols
        t.serverName = Some(hostName)
        t
    }

    private func buildClient(hostName: String): Client {
        var builder = ClientBuilder()
            .tlsConfig(copyTlsConfig(tlsConfig, hostName))
            .autoRedirect(autoRedirect)
            .readTimeout(readTimeout)
            .writeTimeout(writeTimeout)
            .initialWindowSize(initialWindowSize)
            .enablePush(enablePush)
            .headerTableSize(headerTableSize)
            .poolSize(poolCapacity)
        if (httpProxy != '') {
            builder.httpProxy(httpProxy)
        }
        if (httpsProxy != '') {
            builder.httpsProxy(httpsProxy)
        }
        builder.build()
    }

    /**
     * 创建一个一次性请求构建器
     * 返回的 PooledRequest 实例用完即弃，不持有可复用状态
     */
    public func request(): PooledRequest {
        PooledRequest(this)
    }

    /**
     * 借一个 Client（自适应动态池，双倍容量上限）：
     * 1. 优先复用同 host 空闲 Client；
     * 2. 前一半容量（借出总数 < poolCapacity）：无条件新建，直接并行；
     * 3. 后一半容量（poolCapacity ≤ 借出总数 < 2*poolCapacity）：带超时等待归还，
     *    超时仍无空闲才新建（new-after-wait）；
     * 4. 达到 2*poolCapacity 硬顶：只能等待归还，不再新建（复用后回落）。
     */
    internal func borrowClient(hostName: String): Client {
        synchronized(mutex) {
            borrowLocked(hostName)
        }
    }

    /**
     * 锁内执行借出逻辑（持锁调用）
     */
    private func borrowLocked(hostName: String): Client {
        while (true) {
            // 1. 复用空闲
            if (let Some(c) <- takeIdle(hostName)) {
                return c
            }
            let total = getTotal(hostName)
            // 2. 前一半：无条件新建
            if (total < poolCapacity) {
                return createClient(hostName, total, "new=1")
            }
            // 4. 达到硬顶：只能等待归还（由 release 的 notifyAll 唤醒，不轮询）
            if (total >= poolCapacity * 2) {

                cond.wait()
                continue
            }
            // 3. 后一半：带超时等待，超时后新建
            cond.wait(timeout: Duration.millisecond * 100)
            if (let Some(c) <- takeIdle(hostName)) {
                return c
            }
            let total2 = getTotal(hostName)
            if (total2 < poolCapacity * 2) {
                return createClient(hostName, total2, "new-after-wait")
            }
        }
        throw Exception("borrowClient unreachable")
    }

    /**
     * 从空闲列表取一个 Client（锁内调用），无则 None
     */
    private func takeIdle(hostName: String): ?Client {
        let list = idleClients.get(hostName)
        if (!list.isNone()) {
            let lst = list.getOrThrow()
            if (!lst.isEmpty()) {
                let idx = lst.size - 1
                let c = lst[idx]
                lst.remove(idx..(idx + 1))
                return Some(c)
            }
        }
        None
    }

    /**
     * 新建 Client 并计数（锁内调用）
     */
    private func createClient(hostName: String, total: Int64, tag: String): Client {
        let c = buildClient(hostName)
        totalClients[hostName] = total + 1
        c
    }

    /**
     * 归还 Client：空闲未超容量则入池复用；空闲已满则关闭该 Client，
     * 使连接数随并发回落，自动适应负载。归还后唤醒等待中的 borrow。
     */
    internal func releaseClient(c: Client, hostName: String): Unit {
        synchronized(mutex) {
            var list = idleClients.get(hostName)
            if (list.isNone()) {
                var newList = ArrayList<Client>()
                idleClients[hostName] = newList
                list = Some(newList)
            }
            let lst = list.getOrThrow()
            let total = getTotal(hostName)
            if (lst.size >= poolCapacity) {
                c.close()
                totalClients[hostName] = total - 1
            } else {
                lst.add(c)
            }
            cond.notifyAll()
        }
    }

    private func getTotal(hostName: String): Int64 {
        let t = totalClients.get(hostName)
        if (!t.isNone()) {
            t.getOrThrow()
        } else {
            0
        }
    }

    /**
     * 关闭池中所有 Client
     * 注意：须在无并发请求时调用，借出的 Client 不在此处关闭
     */
    public func destroy(): Unit {
        synchronized(mutex) {
            for ((_, list) in idleClients) {
                while (!list.isEmpty()) {
                    let idx = list.size - 1
                    let client = list[idx]
                    list.remove(idx..(idx + 1))
                    client.close()
                }
            }
            idleClients.clear()
            totalClients.clear()
            cond.notifyAll()
        }
    }
}

/**
 * 池化请求构建器
 *
 * 一次性使用，链式设置请求级参数后 send。
 * 不持有连接层配置，不污染池状态。
 */
public class PooledRequest {
    private let pool: LinderHttpClientPool
    private var url: RequestUrl = RequestUrl.from('')
    private var method: String = 'GET'
    private var headers: HttpHeader = HttpHeader()
    private var requestBody: ?RequestBody = None

    public init(pool: LinderHttpClientPool) {
        this.pool = pool
    }

    public func setUrl(v: String): PooledRequest {
        url = RequestUrl.from(v)
        this
    }

    public func setUrl(v: RequestUrl): PooledRequest {
        url = v
        this
    }

    public func setMethod(v: RequestMethod): PooledRequest {
        method = v.toString()
        this
    }

    public func setMethod(v: String): PooledRequest {
        method = v
        this
    }

    public func setHeader(v: HttpHeader): PooledRequest {
        headers = v
        this
    }

    public func setHeader(key: String, value: String): PooledRequest {
        headers.set(key: key, value: value)
        this
    }

    public func setBody(v: RequestBody): PooledRequest {
        requestBody = v
        this
    }

    public func setBody(v: String): PooledRequest {
        requestBody = RequestBody.from(v)
        this
    }

    public func setBody(v: JsonObject): PooledRequest {
        requestBody = RequestBody.from(v)
        this
    }

    public func setBody(v: Array<Byte>): PooledRequest {
        requestBody = RequestBody.from(v)
        this
    }

    public func setBody(v: InputStream): PooledRequest {
        requestBody = RequestBody.from(v)
        this
    }

    public func setBody(v: DataModel): PooledRequest {
        requestBody = RequestBody.from(v)
        this
    }

    public func setBody(v: Form): PooledRequest {
        requestBody = RequestBody.from(v)
        this
    }

    public func setBody(v: MultipartFormData): PooledRequest {
        requestBody = RequestBody.from(v)
        this
    }

    public func clearBody(): PooledRequest {
        requestBody = None
        this
    }

    /**
     * 发送请求
     * 从池按 hostName 借一个 Client，构建 HttpRequest 发送，用完后归还 Client 以复用连接
     */
    public func send(): LinderHttpResponse {
        var requestBuilder = HttpRequestBuilder()
        var res: HttpResponse
        var response: LinderHttpResponse = LinderHttpResponse()

        // 解析 URL，提取 hostName 用于 TLS SNI 及按 host 分组复用 Client
        let parsedUrl = match (url) {
            case RequestUrl.URL(v) => v
            case RequestUrl.STRING(v) => URL.parse(v)
        }
        let hostName = parsedUrl.hostName.toString()

        try {
            if (!requestBody.isNone()) {
                match (requestBody.getOrThrow()) {
                    case RequestBody.String(v) =>
                        requestBuilder.body(v)
                        if (headers.get('content-type').isEmpty()) {
                            headers.set(key: "content-type", value: "text/xml")
                        }
                    case RequestBody.ByteArray(v) =>
                        requestBuilder.body(v)
                        if (headers.get('content-type').isEmpty()) {
                            headers.set(key: "content-type", value: "application/octet-stream")
                        }
                    case RequestBody.InputStream(v) =>
                        requestBuilder.body(v)
                        if (headers.get('content-type').isEmpty()) {
                            headers.set(key: "content-type", value: "application/octet-stream")
                        }
                    case RequestBody.UrlEncoded(v) =>
                        requestBuilder.body(v.toEncodeString())
                        if (headers.get('content-type').isEmpty()) {
                            headers.set(key: "content-type", value: "application/x-www-form-urlencoded")
                        }
                    case RequestBody.Object(v) =>
                        requestBuilder.body(v.toJson().toString())
                        if (headers.get('content-type').isEmpty()) {
                            headers.set(key: "content-type", value: "application/json")
                        }
                    case RequestBody.Json(v) =>
                        requestBuilder.body(v.toString())
                        if (headers.get('content-type').isEmpty()) {
                            headers.set(key: "content-type", value: "application/json")
                        }
                    case RequestBody.Multipart(v) =>
                        requestBuilder.body(v.build())
                        if (headers.get('content-type').isEmpty()) {
                            headers.set(key: "content-type", value: v.getContentType())
                        }
                }
            }

            requestBuilder.method(method).url(URL.encode(parsedUrl.toString())).setHeaders(headers.rawHeaders)
        } catch (e: Exception) {
            throw e
        }

        // 从池借 Client（按 host 分组），发送后归还，复用 TCP/TLS 连接
        let c = pool.borrowClient(hostName)
        try {
            res = requestBuilder.build() |> c.send
            // 关键：归还 Client 前先把响应体完整读入内存缓存，
            // 否则归还后 Client 被并发复用/关闭时，调用方延迟读取 body 流会失败
            let bodyBytes = readAllBytes(res.body)
            let bodyCache = ByteBuffer(bodyBytes)
            pool.releaseClient(c, hostName)
            response = LinderHttpResponse(body: Some(bodyCache),
                bodySize: Some(Int64(bodyCache.bytes().size)),
                status: res.status,
                headers: res.headers,
                isPersistent: res.isPersistent,
                request: res.request)
        } catch (e: Exception) {
            pool.releaseClient(c, hostName)
            throw e
        }

        response
    }
}

/**
 * 把 InputStream 全部读入字节数组
 */
private func readAllBytes(stream: InputStream): Array<Byte> {
    let buffer = ByteBuffer()
    let chunk = Array<Byte>(4096, repeat: 0)
    var n = stream.read(chunk)
    while (n > 0) {
        buffer.write(chunk[0..n])
        n = stream.read(chunk)
    }
    buffer.bytes()
}

# LinderHttp 2.0 API 参考

> 对应版本 2.0.0（仓颉 1.2.0 / stdx）。所有公开类型都在包 `linderHttp` 下，
> 统一 `import linderHttp.*` 即可（顶层包再导出 `linderHttp.http`）。

## 目录

1. [三种用法](#1-三种用法)
2. [LinderHttp（一行式入口）](#2-linderhttp一行式入口)
3. [HttpClient / HttpClientBuilder](#3-httpclient--httpclientbuilder)
4. [RequestBuilder / Request](#4-requestbuilder--request)
5. [Response](#5-response)
6. [Method / Headers / Body / MultipartBody](#6-method--headers--body--multipartbody)
7. [Timeouts / PoolOptions / RetryPolicy / TlsOptions / Http2Options / ClientConfig](#7-配置类型)
8. [错误类型](#8-错误类型)
9. [拦截器与事件](#9-拦截器与事件)
10. [Cookie](#10-cookie)
11. [WebSocket](#11-websocket)
12. [PoolStats](#12-poolstats)
13. [并发用法](#13-并发用法)

---

## 1. 三种用法

```cangjie
import linderHttp.*

// ① 一行式：最省事，内部复用全局共享客户端（长连接/Cookie 都共享）
let text = LinderHttp.text("https://example.com/")

// ② 客户端 + 一行式：隔离配置（池、Cookie、拦截器互不影响）
let client = HttpClientBuilder().maxConnectionsPerHost(16).build()
let response = client.get("https://example.com/")
client.close()

// ③ 客户端 + 链式：需要自定义头/查询/请求体/超时/重试时
let response = client.request(Method.Post, "https://api.example.com/items")
    .header("x-trace", "abc")
    .query("page", "1")
    .jsonObject(payload)
    .timeout(Timeouts.standard().withTotal(Duration.second * 10))
    .retry(RetryPolicy.robust())
    .send()
```

`HttpClient` 与 `Response` 都实现 `Resource`，可以：

```cangjie
try (client = HttpClientBuilder().build()) {
    try (response = client.get("https://example.com/")) {
        println(response.text())
    }
}
```

---

## 2. LinderHttp（一行式入口）

| 方法 | 返回 | 说明 |
|------|------|------|
| `client(): HttpClient` | 客户端 | 取全局共享客户端（可读连接池统计） |
| `shutdown(): Unit` | — | 关闭共享客户端并释放全部长连接 |
| `get(url, headers!, timeouts!)` | `Response` | GET |
| `head(url)` / `options(url)` / `delete(url)` | `Response` | 其它无体方法 |
| `post(url, body)` | `Response` | `body` 可为 `String` / `JsonValue` / `JsonObject` / `HashMap<String,String>` / `Body` |
| `put(url, body)` | `Response` | `String` / `JsonObject` / `Body` |
| `patch(url, body)` | `Response` | `JsonObject` / `Body` |
| `text(url)` / `json(url)` / `jsonObject(url)` / `dataModel(url)` / `bytes(url)` | 各类 | 直接取响应体 |
| `getAll(urls: Array<String>)` | `Array<String>` | 并发取多个 URL 的文本，顺序与入参一致 |

> 需要超时/重试/请求头时用 `LinderHttp.get(url, headers: h, timeouts: t)`，
> 或改用 `HttpClient` 链式写法。

---

## 3. HttpClient / HttpClientBuilder

### 3.1 HttpClient

| 成员 | 说明 |
|------|------|
| `get(url, headers!, timeouts!, retry!)` | 一行式 GET |
| `head/options/delete(url, headers!)` | 一行式其它方法 |
| `post(url, body, headers!)` | 重载：`String` / `JsonValue` / `JsonObject` / `HashMap<String,String>` / `Body` |
| `put(url, body, headers!)` | 重载：`String` / `JsonObject` / `Body` |
| `patch(url, body, headers!)` | 重载：`JsonObject` / `Body` |
| `request(method, url): RequestBuilder` | 链式入口 |
| `send(request): Response` | 发送（响应体按策略落地） |
| `sendStream(request): Response` | 发送并保持响应体流式 |
| `sendAll(requests): Array<Response>` | 并发发送，顺序与入参一致 |
| `websocket(url, subProtocols!, headers!): WebSocket` | 建立 WebSocket |
| `poolStats(): PoolStats` | 连接池快照 |
| `closeIdleConnections(): Int64` | 关闭全部空闲连接组，返回数量 |
| `cookies(): ?CookieStore` | Cookie 存储（未启用则 None） |
| `config(): ClientConfig` | 当前配置副本 |
| `derive(): HttpClientBuilder` | 以当前配置派生 builder（改副本不影响原客户端） |
| `close()` / `isClosed()` | 关闭 / 是否已关闭 |

### 3.2 HttpClientBuilder

| 分类 | 方法 |
|------|------|
| 超时 | `timeout(Timeouts)`、`readTimeout(Duration)`、`writeTimeout(Duration)`、`totalTimeout(Duration)`、`connectTimeout(Duration)` |
| 行为 | `followRedirects(Bool)`、`bodyBufferLimit(Int64)`、`acceptCompression(Bool)` |
| 请求头 | `defaultHeaders(Headers)`、`header(name, value)`、`userAgent(String)` |
| TLS | `tls(TlsOptions)`、`trustAllCertificates()` |
| 代理 | `proxy(http, https)`、`httpProxy(String)`、`httpsProxy(String)`、`useEnvironmentProxy(Bool)` |
| 连接池 | `pool(PoolOptions)`、`maxConnectionsPerHost(Int64)` |
| 重试 | `retry(RetryPolicy)`、`noRetry()` |
| 其它 | `cookies(Bool)`、`http2(Http2Options)`、`listener(EventListener)`、`intercept(Interceptor)` |
| 构建 | `build(): HttpClient` |

示例：

```cangjie
let client = HttpClientBuilder()
    .timeout(Timeouts.standard().withTotal(Duration.second * 30))
    .maxConnectionsPerHost(32)
    .retry(RetryPolicy(maxAttempts: 4, retryOnStatus: [429, 502, 503, 504]))
    .header("x-app", "demo")
    .bodyBufferLimit(512 * 1024)
    .build()
```

---

## 4. RequestBuilder / Request

### 4.1 RequestBuilder（`client.request(...)` / `client.get(...)` 后链式）

| 分类 | 方法 |
|------|------|
| 请求行 | `method(Method)`、`url(String)`、`query(name, value)`、`query(Array<(String,String)>)` |
| 请求头 | `header(name, value)`、`header(name, Int64)`、`addHeader(name, value)`、`headers(Headers)`、`basicAuth(user, password)`、`bearer(token)` |
| 请求体 | `body(Body)`、`text(String, contentType!)`、`json(JsonValue)`、`jsonObject(JsonObject)`、`jsonText(String)`、`dataModel(DataModel)`、`bytes(Array<Byte>, contentType!)`、`form(HashMap)`、`form(Array<(String,String)>)`、`multipart(MultipartBody)`、`streamBody(InputStream, contentType!, length!)`、`fileBody(Path, contentType!)` |
| 行为 | `timeout(Timeouts)`、`readTimeout(Duration)`、`writeTimeout(Duration)`、`totalTimeout(Duration)`、`retry(RetryPolicy)`、`noRetry()`、`streamResponse(Bool)`、`tag(String)` |
| 执行 | `build(): Request`、`send(): Response`、`sendStream(): Response` |

查询参数会自动做 UTF-8 百分号编码，并可安全携带中文、空格、`&`、`=`。

### 4.2 Request（不可变描述）

`method`、`url`（已拼好查询参数）、`headers`、`body`、`timeouts`、`retry`、
`streamResponse`、`tag`；方法：`header(name): ?String`、`hasBody(): Bool`、
`withHeader(name, value)`、`withBody(Body)`、`withUrl(String)`（拦截器里最常用）。

---

## 5. Response

| 成员 | 说明 |
|------|------|
| `status: UInt16` | 状态码 |
| `statusText: String` | 常见状态码短语（如 `Not Found`） |
| `ok` / `isSuccessful` | 2xx |
| `isRedirect` | 3xx |
| `headers: Headers` | 响应头 |
| `url: String` | 最终 URL（自动重定向后） |
| `method: Method` | 请求方法 |
| `attempts: Int64` | 实际尝试次数（含重试） |
| `elapsed: Duration` | 请求耗时（不含调用方读流时间） |
| `protocolVersion: String` | 协议版本 |
| `contentLength: ?Int64` | 长度（透明解压后为解压后长度，已落地时为实际字节数） |
| `contentType: ?String` / `location: ?String` | 常见头 |
| `cookies: Array<Cookie>` | 响应下发的 Cookie |
| `header(name): ?String` / `headerValues(name)` | 取头 |
| `rawResponse(): HttpResponse` | 底层响应（高级用法） |
| `bytes(): Array<Byte>` | 全部字节（可重复调用） |
| `text(): String` | UTF-8 文本 |
| `json(): JsonValue` / `jsonObject(): JsonObject` / `dataModel(): DataModel` | JSON |
| `stream(): InputStream` | 流式读取（流式响应只读一次，读完自动归还连接池） |
| `saveTo(path, overwrite!): Int64` | 把响应体写文件（低层便捷，返回写入字节数） |
| `raiseForStatus(): Response` | ≥400 时抛 `StatusError`，否则返回自身 |
| `close()` / `isClosed()` | 释放（`Resource`） |

响应体策略：

- 默认：长度已知且 ≤ `bodyBufferLimit` 就**读进内存**（保证连接一定复用，且可反复读取）；
- 超出阈值 / 长度未知且试探超限 / 显式 `sendStream` → **流式租约**，
  读完或 `close()` 归还槽位。

---

## 6. Method / Headers / Body / MultipartBody

### Method

`Method.Get/Post/Put/Patch/Delete/Head/Options/Trace/Connect/Custom(String)`；
`toString()`、`Method.parse(String)`、`isIdempotent()`。

### Headers（大小写不敏感、支持多值）

`set(name, value)`、`add(...)`、`setAll(Array<(String,String)>)`、`remove(name)`、`clear()`、
`get(name): Collection<String>`、`first(name): ?String`、`firstOr(name, fallback)`、
`contains(name)`、`names()`、`size()`、`isEmpty()`、`copy()`、`native()`、
`standard()`（默认 `accept` + `user-agent`）、`defaultUserAgent()`；可 `for ((name, values) in headers)`。

### Body

`Body.text(s, contentType!)`、`of(s, contentType!)`、`json(JsonValue|JsonObject)`、
`jsonText(s)`、`dataModel(DataModel)`、`bytes(Array<Byte>, contentType!)`、
`stream(InputStream, contentType!, length!)`、`file(Path, contentType!)`、
`form(HashMap|Array<(String,String)>)`、`multipart(MultipartBody)`、`empty()`；
`mediaType()`、`isStreaming()`、`contentLength()`。

### MultipartBody

```cangjie
let form = MultipartBody.create()
    .text("name", "张三")
    .file("avatar", "photo.png", bytes, contentType: "image/png")
client.post(url, Body.multipart(form))
```

`create(boundary!)`、`boundaryText()`、`text(name, value)`、
`file(name, fileName, content, contentType!)`、`fileFromPath(name, path, fileName!, contentType!)`、
`fileStream(name, fileName, InputStream, contentType!)`、`partCount()`、`contentType()`、`build()`。

---

## 7. 配置类型

### Timeouts

`Timeouts.standard()`（连接 10s / 读写 30s / 总 120s）、`unlimited()`、
`of(read!, write!)`、`withConnect/withRead/withWrite/withTotal(Duration)`；字段
`connect`、`read`、`write`、`total`（都是 `?Duration`）。

`total` 是整次逻辑请求（含重试与退避）的预算：每次尝试前会把读/写超时压到剩余预算以内。

### PoolOptions

`maxConnectionsPerHost`（默认 32，同时也是并发闸门上限）、`idleTimeout`（默认 3 分钟）、
`maxHosts`（默认 64）、`acquireTimeout`（默认 30s）、`liveLeaseTimeout`（默认 5 分钟）；
`PoolOptions.standard()`、`PoolOptions.small()`、`copy()`。

### RetryPolicy

`maxAttempts`、`initialBackoff`、`maxBackoff`、`multiplier`、`jitterRatio`、
`retryOnTimeout`、`retryOnTransport`、`retryOnPoolBusy`、`retryOnStatus`、
`retryNonIdempotent`、`honorRetryAfter`；`none()`、`standard()`、`robust()`、`isRetryable()`。

### HealthPolicy（熔断，默认关闭）

``cangjie
let health = HealthPolicy.standard()   // enabled = true
health.failureThreshold = 5            // 连续传输失败次数
health.cooldown = Duration.second * 10 // 冷却时长
let client = HttpClientBuilder().healthPolicy(health).build()
``# 

- 只统计**传输层**失败（建连/超时/连接中断），4xx/5xx 不计入。
- 冷却期内该 host 直接抛 ErrorKind.CircuitOpen（不重试）；冷却结束放行一次探测，成功即清零恢复。
- HealthPolicy.disabled()（默认）表示不熔断。

### TlsOptions

`TlsOptions.system()`（默认：系统 CA 校验 + 逐 host SNI）、`trustAll()`、
`customCa(pem)`、`native(TlsClientConfig)`、`withServerName(name)`、`withAlpn(Array<String>)`。

### Http2Options

`Http2Options(enabled!, enablePush!, initialWindowSize!, headerTableSize!)`、`standard()`。

### ClientConfig

`timeouts`、`followRedirects`、`defaultHeaders`、`tls`、`pool`、`retry`、`http2`、
`bodyBufferLimit`、`acceptCompression`、`compensateTargetDecoding`、`transportLogLevel`、
`httpProxy`、`httpsProxy`、`useEnvironmentProxy`、`cookiesEnabled`、`userAgent`、`copy()`。

---

## 8. 错误类型

`HttpError <: Exception`：`kind: ErrorKind`、`url`、`attempts`、`cause`、`isRetryable()`、`describe()`。

`ErrorKind`：`Url`、`Connect`、`Timeout`、`Transport`、`Protocol`、`PoolBusy`、`Closed`、
`Status`、`RetryExhausted`、`ResponseBody`；`isRetryable()` 说明哪些会自动重试。

`StatusError <: HttpError`：额外带 `status: UInt16` 与 `bodyPreview: String`（响应体前 512 字节）。

```cangjie
try {
    client.get(url).raiseForStatus()
} catch (error: StatusError) {
    println("HTTP ${error.status}: ${error.bodyPreview}")
} catch (error: HttpError) {
    println("${error.kind} ${error.message} attempts=${error.attempts}")
}
```

---

## 9. 拦截器与事件

```cangjie
let interceptor = Interceptor(
    onRequest: { request => request.withHeader("x-sign", sign(request)) },
    onResponse: { request, response => println("${response.status} ${request.url}") },
    onError: { request, error => println("失败：${error.describe()}") }
)
let listener = EventListener(
    onRequestStart: { request => () },
    onRetry: { event => println("重试 ${event.attempt}/${event.maxAttempts} 等待 ${event.delay}") },
    onRequestEnd: { request, response, elapsed => () },
    onRequestFailed: { request, error => () },
    onConnectionCreated: { hostKey => println("新建连接组 ${hostKey}") },
    onConnectionReused: { hostKey => println("复用连接组 ${hostKey}") },
    onConnectionEvicted: { hostKey => println("回收连接组 ${hostKey}") }
)
let client = HttpClientBuilder().intercept(interceptor).listener(listener).build()
```

拦截器的一个逻辑请求只触发一次（不在每次重试时重复触发）。

---

## 10. Cookie

`CookieStore`：默认随 `HttpClient` 启用。`size()`、`all()`、`clear()`、
`store(url, setCookieHeaders)`、`headerFor(url): ?String`（由引擎内部调用）。

`Cookie`：`name`、`value`、`domain`、`path`、`secure`、`httpOnly`、`expiresAt`、`raw`、
`isExpired(now)`、`matches(host, path, secureRequest)`、`toCookieLine()`。

---

## 11. WebSocket

```cangjie
let client = HttpClientBuilder().build()
let socket = client.websocket("wss://echo.example.com/ws", subProtocols: ["chat"])
socket.sendText("hello")
match (socket.receive()) {
    case Some(WebSocketMessage.Text(text)) => println(text)
    case Some(WebSocketMessage.Binary(data)) => println("${data.size} bytes")
    case Some(WebSocketMessage.Ping(_)) => ()      // 库已自动回 Pong
    case Some(WebSocketMessage.Closed(_, _)) => ()
    case Some(WebSocketMessage.Pong(_)) => ()
    case None => ()
}
socket.close()
client.close()
```

`WebSocket`：`url()`、`subProtocol`、`sendText`、`sendBinary`、`ping(payload!)`、
`receive(): ?WebSocketMessage`、`receiveText()`、`receiveBinary()`、`close()`、`isClosed()`。
分片消息由库自动拼装；`ws://` 与 `wss://` 都支持。

---

## 12. PoolStats

`hostGroups`、`activeRequests`、`openStreams`、`totalRequests`、`createdGroups`、
`reusedGroups`、`evictedGroups`、`retries`、`reuseRate()`、`toString()`。

```cangjie
println(client.poolStats())
// PoolStats(hosts=1, active=0, streams=0, requests=6, created=1, reused=5, evicted=0, retries=0)
```

---

## 13. 并发用法

```cangjie
// 同一客户端并发发送（内部走闸门排队，不会出现 Too many connections）
let requests = ArrayList<Request>()
for (index in 0..64) {
    requests.add(client.request(Method.Get, "https://api.example.com/ping").build())
}
let responses = client.sendAll(requests.toArray())

// 全局共享客户端并发取文本
let texts = LinderHttp.getAll(["https://a/", "https://b/", "https://c/"])
```

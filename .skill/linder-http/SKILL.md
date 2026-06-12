---
name: linder-http
description: "提供 LinderHttp 仓颉 HTTP 客户端库的完整 API 参考和使用指南，包括 LinderHttpClient 链式调用、HttpQuick 快捷请求、WebSocket 客户端、拦截器、Multipart 文件上传、TLS/HTTP2 配置等。当用户询问 LinderHttp 库的使用方法、API 调用、示例代码或遇到相关开发问题时触发。"
---

# LinderHttp — 仓颉 HTTP 客户端库

> 基于仓颉语言开发的现代化 HTTP 客户端库，提供简洁优雅的 API 和强大的功能支持。

## 包结构

```
linderHttp/
├── LinderHttpClient      # HTTP 客户端主类（链式调用）
├── LinderHttpResponse    # HTTP 响应封装
├── HttpQuick             # 快捷请求类（类似 axios）
├── HttpHeader            # HTTP 头容器
├── Interceptor           # 请求/响应/错误拦截器
├── WebSocketClient       # WebSocket 客户端
├── MultipartFormData     # Multipart 表单数据
├── RequestMethod         # 请求方法枚举
├── RequestBody           # 请求体枚举
├── RequestUrl            # URL 封装枚举
├── ConflictMethod        # 文件冲突处理枚举
├── defaultTlsConfig()    # 默认 TLS 配置
└── exportToFile          # 文件导出工具
```

## 1. LinderHttpClient（核心类）

### 构造函数

```cangjie
public init(
    url!: RequestUrl = RequestUrl.from(''),
    serverName!: String = '',
    tlsConfig!: ?TlsClientConfig = None,
    httpHeader!: ?HttpHeader = None,
    stdHeaders!: ?HttpHeaders = None,
    interceptor!: ?Interceptor = None,
    method!: RequestMethod = RequestMethod.GET,
    requestBody!: ?RequestBody = None,
    autoRedirect!: Bool = true,
    readTimeout!: Duration = Duration.second * 15,
    writeTimeout!: Duration = Duration.second * 15,
    initialWindowSize!: UInt32 = 65535,
    enablePush!: Bool = true,
    headerTableSize!: UInt32 = 4096,
    httpProxy!: String = '',
    httpsProxy!: String = ''
)
```

**约束：** `httpHeader` 和 `stdHeaders` 不可同时设置，否则抛出 `IllegalArgumentException`。

### 公共属性

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `url` | `RequestUrl` | 空 | 请求 URL |
| `headers` | `HttpHeader` | 空容器 | HTTP 请求头 |
| `tlsConfig` | `TlsClientConfig` | `defaultTlsConfig()` | TLS 配置 |
| `method` | `String` | `'GET'` | HTTP 方法 |
| `requestBody` | `?RequestBody` | `None` | 请求体 |
| `autoRedirect` | `Bool` | `true` | 自动重定向 |
| `readTimeout` | `Duration` | 15s | 读超时 |
| `writeTimeout` | `Duration` | 15s | 写超时 |
| `initialWindowSize` | `UInt32` | 65535 | HTTP/2 流控窗口 |
| `enablePush` | `Bool` | `true` | HTTP/2 服务器推送 |
| `headerTableSize` | `UInt32` | 4096 | HTTP/2 Hpack 表大小 |
| `httpProxy` | `String` | `''` | HTTP 代理 |
| `httpsProxy` | `String` | `''` | HTTPS 代理 |

### 链式配置方法

所有 set 方法均返回 `LinderHttpClient` 自身，支持链式调用：

```cangjie
client.setUrl(v: RequestUrl | String | URL): LinderHttpClient
client.setHeader(v: HttpHeaders | HttpHeader | HashMap<String, String>): LinderHttpClient
client.setMethod(v: RequestMethod | String): LinderHttpClient
client.setBody(v: RequestBody | String | InputStream | Array<Byte> | DataModel | JsonObject | Form | MultipartFormData): LinderHttpClient
client.setInterceptor(v: Interceptor): LinderHttpClient
client.setServerName(v: String): LinderHttpClient       // 自定义TLS握手域名
client.setAutoRedirect(v: Bool): LinderHttpClient
client.setReadTimeout(v: Duration): LinderHttpClient
client.setWriteTimeout(v: Duration): LinderHttpClient
client.setInitialWindowSize(v: UInt32): LinderHttpClient
client.setEnablePush(v: Bool): LinderHttpClient
client.setHeaderTableSize(v: UInt32): LinderHttpClient
client.setHttpProxy(v: String): LinderHttpClient
client.setHttpsProxy(v: String): LinderHttpClient
client.clearBody(): LinderHttpClient
client.setDefaultHeader(): LinderHttpClient
client.destroy(): LinderHttpClient                       // 取消请求并关闭连接
```

**注意：** `setServerName()` 会被后续 `setUrl()` 调用覆盖，如需自定义域名应在 `setUrl()` 之后调用。

### 发送请求

```cangjie
public func send(needSetDefaultHeader!: Bool = false): LinderHttpResponse
```

**执行流程：**
1. 触发 `onRequest` 拦截器（请求前）
2. 构建并发送 HTTP 请求
3. 触发 `onError` 拦截器（构建或发送异常时）
4. 创建 `LinderHttpResponse` 响应对象
5. 触发 `onResponse` 拦截器（响应后）
6. 自动清空请求体（`clearBody()`）

## 2. LinderHttpResponse（响应类）

### 公共属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `status` | `Int64` | HTTP 状态码 |
| `body` | `Array<Byte>` | 响应体原始字节 |
| `bodySize` | `Int64` | 响应体大小 |
| `headers` | `HttpHeaders` | 响应头 |
| `isPersistent` | `Bool` | 是否持久连接 |
| `request` | `?HttpRequest` | 原始请求对象 |

### 计算属性

```cangjie
location: ?Array<String>       // 重定向地址
contentType: ?Array<String>    // Content-Type
setCookie: ?Array<String>      // Set-Cookie
```

### 方法

```cangjie
getHeader(header: String): ?Array<String>              // 获取响应头
getBodyStream(): InputStream                            // 获取响应体流
getBodyString(): String                                 // 获取字符串响应体
getBodyJsonString(): String                             // 获取 JSON 字符串
getBodyJsonValue(): JsonValue                           // 获取 JSON Value
getBodyJsonObject(): JsonObject                         // 获取 JSON 对象
getBodyDataModel(): DataModel                           // 获取 DataModel
getBodyByteBuffer(): ByteBuffer                         // 获取 ByteBuffer
getBodyFile(filePath!: Path, conflictMethod!: ConflictMethod = ConflictMethod.ASK): Unit  // 保存为文件
printHeaders(): Unit                                    // 打印所有响应头
```

## 3. HttpHeader（HTTP 头容器）

### 构造方法

```cangjie
public init()
public init(v: HttpHeaders)  // 从标准 HttpHeaders 导入
```

### 方法

```cangjie
setAll(v: HttpHeaders): HttpHeader          // 批量设值（覆盖）
set(key!: String, value!: String): HttpHeader  // 设值（覆盖）
add(key!: String, value!: String): HttpHeader  // 增加值（同键多值）
delete(key!: String): HttpHeader             // 删除
get(key: String): Collection<String>         // 获取所有值
getFirst(key: String): ?String               // 获取第一个值
isEmpty(): Bool                              // 是否为空
printlnAll(): Unit                           // 打印所有头
```

## 4. Interceptor（拦截器）

### 属性

```cangjie
onRequest: ?(LinderHttpClient) -> Unit              // 请求前拦截
onError: ?(Exception, LinderHttpClient) -> Unit     // 错误拦截
onResponse: ?(LinderHttpResponse) -> Unit            // 响应后拦截
```

### 构造方法

```cangjie
public init(
    onRequest!: ?(LinderHttpClient) -> Unit = None,
    onError!: ?(Exception, LinderHttpClient) -> Unit = None,
    onResponse!: ?(LinderHttpResponse) -> Unit = None
)
```

**说明：** 全部为可选参数，只注册需要的拦截器即可。

**错误处理：** 如果注册了 `onError` 但执行时 `onError` 不存在，或者未注册 `onError`，异常会继续向上抛出。

## 5. HttpQuick（快捷请求类）

所有方法均为静态方法：

```cangjie
get(url: String | URL): LinderHttpResponse
get(url: String, headers: HashMap<String, String>): LinderHttpResponse
post(url: String | URL, body: String): LinderHttpResponse
post(url: String, body: JsonObject): LinderHttpResponse
post(url: String, body: Form): LinderHttpResponse
put(url: String, body: String | JsonObject): LinderHttpResponse
delete(url: String | URL): LinderHttpResponse
head(url: String): LinderHttpResponse
options(url: String): LinderHttpResponse
patch(url: String, body: String | JsonObject): LinderHttpResponse
```

## 6. WebSocketClient（WebSocket 客户端）

### 属性

```cangjie
url: URL                        // 连接 URL
subProtocols: ArrayList<String> // 子协议列表
headers: HttpHeaders            // 请求头
tlsConfig: ?TlsClientConfig     // TLS 配置
selectedSubProtocol: ?String    // （计算属性）选定子协议，连接成功后可用
```

### 构造方法

```cangjie
public init(url: String)
public init(url: URL)
```

### 方法

```cangjie
setSubProtocols(protocols: ArrayList<String> | Array<String>): WebSocketClient
addSubProtocol(protocol: String): WebSocketClient
setHeaders(headers: HttpHeaders): WebSocketClient
addHeader(name: String, value: String): WebSocketClient
setTlsConfig(config: TlsClientConfig): WebSocketClient
connect(): HttpHeaders                       // 连接服务器，返回响应头
sendText(message: String): Unit              // 发送文本消息
sendBinary(data: Array<UInt8>): Unit         // 发送二进制消息
ping(): Unit                                 // Ping
ping(payload: Array<UInt8>): Unit            // Ping（带负载）
pong(payload: Array<UInt8>): Unit            // Pong
read(): WebSocketFrame                       // 读取消息帧
readText(): ?String                          // 读取文本消息（自动处理分片）
readBinary(): ?Array<UInt8>                  // 读取二进制消息（自动处理分片）
close(status!: UInt16 = 1000): Unit          // 发送关闭帧
closeConnection(status!: UInt16 = 1000): Unit // 关闭连接
isConnected(): Bool                          // 检查连接状态
getRawWebSocket(): ?WebSocket                // 获取底层 WebSocket 对象
```

**消息读取说明：** `readText()` 和 `readBinary()` 内部自动处理 `ContinuationWebFrame` 分片，并自动响应 `PingWebFrame` 帧（发送 Pong），遇到 `CloseWebFrame` 返回 `None`。

## 7. 数据模型

### RequestMethod 枚举

```cangjie
public enum RequestMethod {
    GET | POST | PUT | DELETE | HEAD | OPTIONS | PATCH | CUSTOM(String)
}
```

### RequestBody 枚举

```cangjie
public enum RequestBody {
    String(String)
    ByteArray(Array<Byte>)
    InputStream(InputStream)
    UrlEncoded(Form)
    Object(DataModel)
    Json(JsonObject)
    Multipart(MultipartFormData)
}
```

工厂方法：`RequestBody.from(v: String | InputStream | Array<Byte> | DataModel | JsonObject | Form | MultipartFormData): RequestBody`

### RequestUrl 枚举

```cangjie
public enum RequestUrl {
    STRING(String)
    URL(URL)
}
```

工厂方法：`RequestUrl.from(v: String | URL): RequestUrl`

### MultipartFormData

```cangjie
public class MultipartFormData {
    public init()
    getBoundary(): String
    addText(name: String, value: String): MultipartFormData
    addFile(name: String, filename: String, content: Array<Byte>): MultipartFormData
    addFileStream(name: String, filename: String, stream: InputStream): MultipartFormData
    getParts(): Array<MultipartPart>
    clear(): Unit
    build(): Array<Byte>
    getContentType(): String    // 如 "multipart/form-data; boundary=..."
}
```

### ConflictMethod 枚举（文件冲突处理）

```cangjie
public enum ConflictMethod {
    ASK       // 询问
    RENAME    // 重命名
    SKIP      // 跳过
    OVERRIDE  // 覆盖
}
```

## 8. 工具函数

### defaultTlsConfig()

```cangjie
public func defaultTlsConfig(): TlsClientConfig
```

生成带合理默认值的 TLS 配置。

### exportToFile

```cangjie
public func exportToFile(body: Array<Byte>, filePath: Path, conflictMethod: ConflictMethod = ConflictMethod.ASK): Unit
```

将字节数据导出到文件，支持冲突处理策略。

## 9. 使用示例

### 基础 GET 请求

```cangjie
import linderHttp.*

// 快捷方法
let response = HttpQuick.get("https://api.example.com/data")
println(response.getBodyString())

// 链式调用
let response = LinderHttpClient(url: "https://api.example.com/data")
    .setHeader("Authorization", "Bearer token123")
    .send()
println("状态码: ${response.status}")
```

### POST JSON 数据

```cangjie
import linderHttp.*
import stdx.encoding.json.*

let json = JsonObject()
json.put("name", "张三")
json.put("age", 25)

let response = HttpQuick.post("https://api.example.com/users", json)

// 或链式调用
let response = LinderHttpClient(url: "https://api.example.com/users")
    .setMethod(RequestMethod.POST)
    .setBody(json)
    .send()
```

### 文件上传（Multipart）

```cangjie
let multipart = MultipartFormData()
    .addText("username", "张三")
    .addFile("avatar", "photo.jpg", fileBytes)

let response = LinderHttpClient(url: "https://api.example.com/upload")
    .setMethod(RequestMethod.POST)
    .setBody(multipart)
    .send()
```

### 使用拦截器

```cangjie
let interceptor = Interceptor(
    onRequest: { client =>
        println("发送请求: ${client.url}")
    },
    onError: { error, client =>
        println("请求失败: ${error.message}")
    },
    onResponse: { response =>
        println("收到响应: ${response.status}")
    }
)

let response = LinderHttpClient(
    url: "https://api.example.com/data",
    interceptor: interceptor
).send()
```

### WebSocket

```cangjie
let ws = WebSocketClient("wss://echo.websocket.org")
ws.connect()
ws.sendText("Hello, WebSocket!")

if (let Some(message) <- ws.readText()) {
    println("收到消息: ${message}")
}
ws.close()
```

### 配置超时和代理

```cangjie
let response = LinderHttpClient(url: "https://api.example.com/data")
    .setReadTimeout(Duration.second * 30)
    .setWriteTimeout(Duration.second * 10)
    .setHttpProxy("http://proxy.example.com:8080")
    .setHttpsProxy("https://proxy.example.com:8443")
    .send()
```

### 响应处理

```cangjie
let response = HttpQuick.get("https://api.example.com/data")

println("状态码: ${response.status}")

// 字符串响应体
let body = response.getBodyString()

// JSON 处理
let json = response.getBodyJsonObject()

// 获取响应头
let contentType = response.getHeader("content-type")

// 保存为文件
response.getBodyFile(filePath: Path("./data.json"))
```

## 10. 重要注意事项

1. **双 Header 约束：** `httpHeader` 与 `stdHeaders` 不可同时设置，否则抛出 `IllegalArgumentException`。
2. **TLS 域名优先级：** `serverName` 参数优先级低于 `tlsConfig`，同时设置时以 `tlsConfig` 为准。
3. **setServerName 调用顺序：** 会被后续 `setUrl()` 覆盖，如需设置应在 `setUrl()` 之后调用。
4. **请求体自动清空：** `send()` 执行完毕后自动调用 `clearBody()`。
5. **拦截器错误处理：** 若 `onError` 为 `None` 或拦截器函数不存在，异常会继续向上抛出。
6. **包导入：** 所有类位于 `linderHttp` 包下，使用时需 `import linderHttp.*`。

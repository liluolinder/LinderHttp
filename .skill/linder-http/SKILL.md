---
name: linder-http
description: "提供 LinderHttp 2.0 仓颉 HTTP 客户端库的 API 参考与使用指南：HttpClient/HttpClientBuilder、RequestBuilder 链式请求、一行式 LinderHttp 便捷入口、连接池与长连接、重试与四级超时、Cookie、拦截器与事件监听、multipart、WebSocket、TLS 配置。当用户询问 LinderHttp 的用法、API、示例代码或排查相关问题时触发。"
---

# LinderHttp 2.0 — 仓颉 HTTP 客户端库

> 设计参考 OkHttp / axios / requests / httpx 的思路，但 API 是本库自己的风格。
> 详细参考：[doc/feature_api.md](../../doc/feature_api.md)、[doc/ARCHITECTURE.md](../../doc/ARCHITECTURE.md)。

## 包结构

```
linderHttp/                    顶层包（public import linderHttp.http.*）
└── linderHttp.http
    ├── LinderHttp             一行式全局入口
    ├── HttpClient             客户端（配置不可变、线程安全、持有连接池）
    ├── HttpClientBuilder      客户端构建器
    ├── RequestBuilder/Request 链式请求 / 不可变请求描述
    ├── Response               响应（实现 Resource，可 try-with-resources）
    ├── Method/Headers/Body/MultipartBody
    ├── Timeouts/PoolOptions/RetryPolicy/TlsOptions/Http2Options/ClientConfig
    ├── HttpError/StatusError/ErrorKind
    ├── Interceptor/EventListener/RetryEvent
    ├── Cookie/CookieStore
    ├── WebSocket/WebSocketMessage
    └── PoolStats
```

导入方式只有一种：`import linderHttp.*`。

## 三种用法

```cangjie
import linderHttp.*

// ① 一行式（共享全局客户端：长连接与 Cookie 都共享）
let text = LinderHttp.text("https://example.com/")
let value = LinderHttp.json("https://api.example.com/data")

// ② 客户端 + 一行式（配置隔离）
let client = HttpClientBuilder().maxConnectionsPerHost(16).build()
let response = client.get("https://example.com/")
client.close()

// ③ 客户端 + 链式（需要头/查询/体/超时/重试）
let response = client.request(Method.Post, "https://api.example.com/items")
    .header("x-trace", "abc")
    .query("page", "1")
    .jsonObject(payload)
    .bearer(token)
    .timeout(Timeouts.standard().withTotal(Duration.second * 10))
    .retry(RetryPolicy.robust())
    .send()
println("${response.status} ${response.text()}")
```

客户端与响应都是 `Resource`：

```cangjie
try (client = HttpClientBuilder().build()) {
    try (response = client.get(url)) {
        println(response.text())
    }
}
```

## 常用 API 速查

### HttpClientBuilder

`timeout/readTimeout/writeTimeout/totalTimeout/connectTimeout`、`followRedirects`、
`defaultHeaders/header/userAgent`、`tls/trustAllCertificates`、
`proxy/httpProxy/httpsProxy/useEnvironmentProxy`、`pool/maxConnectionsPerHost`、
`retry/noRetry`、`cookies`、`http2`、`bodyBufferLimit`、`acceptCompression`、
`listener`、`intercept`、`build`。

### HttpClient

`get/head/options/delete`、`post/put/patch`（多个体类型重载）、`request(method, url)`、
`send/sendStream/sendAll`、`websocket(url, subProtocols!, headers!)`、
`poolStats()`、`closeIdleConnections()`、`cookies()`、`config()`、`derive()`、`close()`。

### RequestBuilder

`method`、`url`、`query(name, value)`、`header/addHeader/headers`、`basicAuth`、`bearer`、
`body/text/json/jsonObject/jsonText/dataModel/bytes/form/multipart/streamBody/fileBody`、
`timeout/readTimeout/writeTimeout/totalTimeout`、`retry/noRetry`、`streamResponse`、`tag`、
`build/send/sendStream`。

### Response

`status`、`statusText`、`ok/isSuccessful/isRedirect`、`headers`、`url`、`method`、
`attempts`、`elapsed`、`contentLength`、`contentType`、`location`、`cookies`、
`header(name)`、`bytes()`、`text()`、`json()`、`jsonObject()`、`dataModel()`、
`stream()`、`saveTo(path)`、`raiseForStatus()`、`close()`。

### Request（拦截器里用）

`withHeader(name, value)`、`withBody(Body)`、`withUrl(String)`。

### 其它

- `RetryPolicy.standard()/robust()/none()`；字段 `maxAttempts`、`initialBackoff`、`retryOnStatus` 等。
- `Timeouts.standard()/unlimited()/withRead/withWrite/withTotal`。
- `PoolOptions.standard()/small()`；字段 `maxConnectionsPerHost`、`idleTimeout`、`maxHosts`、`acquireTimeout`。
- `TlsOptions.system()`（默认，系统 CA + 逐 host SNI）、`trustAll()`、`customCa(pem)`。
- `Interceptor(onRequest/onResponse/onError)`、`EventListener(...onConnectionReused 等)`。
- `WebSocket`：`sendText/sendBinary/ping/receive/receiveText/receiveBinary/close`；
  `WebSocketMessage`：`Text/Binary/Ping/Pong/Closed`。
- `HttpError`（`kind`/`url`/`attempts`/`cause`/`describe()`）、`StatusError`（`status`/`bodyPreview`）。

## 行为约定（写代码时必须知道）

1. **响应体策略**：默认小响应体自动读进内存（连接一定复用、可反复读）；超过
   `bodyBufferLimit`、长度未知且试探超限、或显式 `sendStream()` 时保持流式 —— 此时必须读完
   或调用 `Response.close()`，否则只能等池的租约兜底回收。
2. **重试范围**：默认只重试幂等方法；流式请求体不重试；POST/PATCH 需 `retryNonIdempotent: true`。
3. **状态码重试耗尽后返回最后一个响应**（不抛异常）；要抛异常请显式 `response.raiseForStatus()`。
4. **默认校验证书**；自签名/内网调试用 `HttpClientBuilder().trustAllCertificates()`。
5. **File download 不在本库**：断点续传/分片/进度属于 `selineDownload`，本库只提供
   `sendStream()`、`Response.stream()`、`Response.saveTo()` 这些原语。
6. **WebSocket 独占连接**，随 `WebSocket.close()` 释放，不占普通请求连接池。
7. 底层 stdx 的两个已知缺陷本库已补偿（不要重复处理）：请求目标会被百分号解码
   （`ClientConfig.compensateTargetDecoding`）、响应体不会自动解压
   （`ClientConfig.acceptCompression`）。

## 实例测试

```
cd C:\Project\Cangjie\demo\http_demo
cjpm build
target\release\bin\main.exe          # 全部断言
$env:HTTP_DEMO_FILTER="core"         # 长连接 / 连接池 / 稳定性
$env:HTTP_DEMO_FILTER="conv"         # 便捷函数
$env:HTTP_DEMO_FILTER="ws"           # WebSocket
```

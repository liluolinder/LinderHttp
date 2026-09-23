# LinderHttp 2.0 架构与设计说明

## 1. 分层

```
┌──────────────────────────────────────────────────────────────┐
│ facade.cj        LinderHttp（一行式全局入口，复用共享客户端）  │
├──────────────────────────────────────────────────────────────┤
│ client.cj        HttpClient（不可变配置 + 池 + 拦截器）        │
│                  HttpClientBuilder（逐项配置）                 │
│                  ── 发送管线：拦截 → 分池 → 闸门 → 发送        │
│                     → 解码 → 重试判定 → 落地/租约              │
├──────────────────────────────────────────────────────────────┤
│ pool.cj          每 host 连接组 + 并发闸门 + 空闲/租约回收      │
│ retry.cj         退避与可重试判定                              │
│ options.cj       Timeouts / PoolOptions / Http2Options / Config│
│ tls.cj           按 host 生成 TlsClientConfig（SNI 必须逐 host）│
├──────────────────────────────────────────────────────────────┤
│ request.cj / response.cj / headers.cj / body.cj / cookie.cj   │
│ events.cj / multipart.cj / websocket.cj / error.cj / method.cj│
├──────────────────────────────────────────────────────────────┤
│ stdx.net.http（TCP/TLS/HTTP1.1/HTTP2/WebSocket 握手）          │
└──────────────────────────────────────────────────────────────┘
```

顶层包 `linderHttp` 只有一句 `public import linderHttp.http.*`，使用方统一 `import linderHttp.*`。

## 2. 长连接与连接池

**核心判断：stdx 的一个 `Client` 内部已经自带「同 host:port 的连接池」**，所以本库
**每个 host 只持有一个 `Client`**，由它负责真正的 TCP/TLS 长连接复用；本库负责的是
上层并发治理与生命周期。

- **分键**：`scheme://host:port`。TLS 必须逐 host 生成（SNI 不会自动填），因此连接组天然按 host 隔离。
- **每 host 只建一组**：避免「一个请求一个 Client」导致握手风暴（旧实现正是每请求新建 Client，连接从不复用）。
- **空闲回收** `idleTimeout`：某组空闲超过阈值就关闭，避免长期占用。
- **host 上限** `maxHosts`：超出后按 LRU 淘汰**完全空闲**的连接组；无空闲可淘汰时明确报错，而不是无限增长。
- **流式租约兜底** `liveLeaseTimeout`：调用方拿到流式响应体后忘记读完，租约会超时并把该连接组整体回收，
  防止槽位永久泄漏。

### 并发闸门（关键修复）

stdx 在「同一 server 的并发数 > `poolSize`」时直接抛
`HttpException: Too many connections to the same server!`（实测：`poolSize=2`、8 并发时 6 个失败）。

本库把 `poolSize` 设为 `maxConnectionsPerHost`，并在上层用**同一数值做闸门**：
超出并发就在闸门前排队，直到有槽位或 `acquireTimeout` 超时。实测 `maxConnectionsPerHost=2`
时 12 个并发请求 **全部成功**（排队完成，耗时毫秒级）。

### 流生命周期（保证连接一定被归还）

响应体有两类处理：

1. **落地内存**（长度已知且 ≤ `bodyBufferLimit`，或长度未知但试探读取后未超阈值）：
   发送返回前就把 body 读完并释放槽位 —— HTTP/1.1 只有读完 body，连接才会回到池里，
   所以这条路径**保证复用**。
2. **流式租约**（显式 `sendStream` / `streamResponse(true)`、长度超过阈值、或压缩体超阈值）：
   槽位转为「租约」，`Response.stream()` 返回包装流，读到 EOF 自动归还；调用方提前放弃时
   调 `Response.close()` 归还，超时未归还则由池的兜底回收处理。

`sendStream` 路径还会把「已读的一段」与「剩余实流」拼成 `PrefixedStream`，
配合 `DecompressInputStream` 实现**流式解压**，大响应既不进内存也不丢编码。

## 3. 高稳定性

| 机制 | 取值 / 行为 |
|------|-------------|
| 重试范围 | 默认只重试幂等方法（GET/HEAD/PUT/DELETE/OPTIONS/TRACE）；流式请求体默认不重试；POST/PATCH 需显式开启 |
| 重试条件 | 建连失败、超时、传输中断、池繁忙、协议错误；状态码维度可配（默认 429/502/503/504） |
| 退避 | 指数增长 + ±25% 抖动，`initialBackoff=200ms`、`maxBackoff=10s`；可选遵守 `Retry-After` |
| 总预算 | `Timeouts.total` 作为整次请求（含重试与退避）预算；**每次尝试前把读/写超时压到剩余预算以内**，超预算即停止重试 |
| 熔断 | HealthPolicy（默认关闭）：只统计传输层失败，达到 ailureThreshold 后进入 cooldown 冷却，期间该 host 直接抛 ErrorKind.CircuitOpen 快速失败；冷却结束放行一次探测，成功即清零恢复。实测：阈值 2 时第 3 次请求 0ms 短路，冷却后探测回到真实建连 |
| 错误模型 | 统一 `HttpError`（带 `kind`/`url`/`attempts`/`cause`）+ `StatusError`（带状态码与响应体片段），避免 `catch` 一堆子类 |
| 线程安全 | 池用 `Mutex + Condition`；统计用 `AtomicInt64`；一个 `Client` 实测可安全承载 64 并发 |
| 关闭语义 | `HttpClient.close()` 后新请求抛 `Closed`；`closeIdleConnections()` 只回收空闲组，不影响在途请求 |
| 默认 TLS | **默认校验证书**（系统 CA）+ 逐 host SNI；`trustAllCertificates()` 才是关闭校验 |

### 默认安全取向的变化

旧实现默认 `TrustAll`（不校验证书）。新实现默认系统 CA 校验：既更安全，实测也更少握手失败
（同一台机器上对 `example.com`：`TrustAll` 出现过握手失败，`Default` 校验模式稳定 200）。

## 4. 便捷性

- **一行式**（对标 requests/axios）：`LinderHttp.text/json/jsonObject/dataModel/bytes/get/post/...`，
  内部复用同一个共享客户端，因此同样享受长连接与 Cookie。
- **链式**（需要精细控制时）：`client.request(Method.Post, url).header(...).query(...).jsonObject(...).bearer(...).timeout(...).retry(...).send()`。
- **并发**：`client.sendAll(requests)` 按序返回；`LinderHttp.getAll(urls)` 并发取文本。
- **拦截器**：`Interceptor(onRequest: { r => r.withHeader("x-sign", sign(r)) }, onResponse: ..., onError: ...)`，
  一个逻辑请求只触发一次（不在每次重试时重复触发）。
- **事件**：`EventListener` 提供请求开始/结束/失败、重试、以及**连接创建/复用/回收**事件，
  后者是「长连接到底有没有复用」最直接的证据。

## 5. 实测发现的平台行为（本库已适配 / 规避）

以下都是在本机（仓颉 1.2.0 / `stdx`）实测得到的结论，直接决定了实现方式：

1. **HTTPS 必须显式提供 `tlsConfig`**，否则抛
   `HttpException: TLS must be configured when HTTPS requests are sent.`。
   `TlsClientConfig.serverName`（SNI）**不会自动填**，必须逐 host 设置，否则握手失败。
2. **并发超过 `poolSize` 会抛异常**（见 §2），必须自己加闸门。
3. **请求目标会被百分号解码后再上线**：
   交给 stdx `?q=a%20b`，线路上的却是 `?q=a b`（服务端 505）；`%2F`→`/`、`%26`→`&`、`%3D`→`=`；
   路径同理（`/a%20b` 会变成 `/a b`）。本库的补偿：把路径与查询里已有的 `%` 再转义一次
   （`%`→`%25`），底层解码一次后线路上恰好恢复成正确的 `%xx`。
   开关：`ClientConfig.compensateTargetDecoding`（默认 true，工具链修好后可关）。
4. **响应体不会自动解压**：声明 `Accept-Encoding: gzip` 后拿到的是原始压缩字节。
   本库自己接管解压（`gzip`/`deflate`），压缩体因为「压缩后长度不可信」，读取一律按
   `bodyBufferLimit` 设上限，避免压缩炸弹。开关：`ClientConfig.acceptCompression`。
5. **WebSocket 客户端握手需要 `stdx.crypto.kit` 被导入**（否则运行期抛
   `CryptoException: Global crypto kit is not set`），本库在 prelude 中显式引入该注册包。
6. `HttpResponse.bodySize` / `content-length` 是压缩前（即线路上）的长度，
   透明解压后 `Response.contentLength` 会报告**解压后的实际长度**。

## 6. 验收：实例测试覆盖

测试工程 `demo/http_demo` 自带本地测试服务器（重试、超时、断点行为都在本机可控复现），
共 141 项断言、全部通过（`main.exe` 退出码 0）。覆盖：

| 组 | 内容 |
|----|------|
| 1–3 | 长连接复用（建 1 组 / 复用 5 次 / 事件计数）、并发闸门（上限 2×12 并发）、多 host 分池 |
| 4–6 | 状态码重试（503→503→200，尝试 3 次）、重试耗尽返回最后响应、关闭重试 |
| 7–12 | 读超时、总预算约束、建连失败分类与次数、URL 非法分类、关闭后拒绝、`raiseForStatus` 与重定向 |
| 13 | 64 并发压力（连接组仍为 1、无遗留活跃请求） |
| 25 | 熔断：连续 2 次传输失败后第 3 次 CircuitOpen 0ms 短路，冷却后放行探测 |
| 14–16 | 一行式 API、链式请求与参数编码（中文/空格/`&`/`=`）、JSON/表单/multipart/字节体 |
| 18–19 | Cookie 自动管理与清空、拦截器改写请求、重试/失败事件、`derive()` 派生客户端 |
| 20 | WebSocket 文本/二进制回显与关闭 |
| 21 | 大响应流式（1MB > 阈值，租约归还后 `openStreams=0`） |
| 22–23 | 真实公网 HTTPS：同 host 建组 1 次、第二次复用（665ms → 156ms）、example.com/mojang 200 |
| 24 | 透明解压：gzip 体在内存路径与流式路径都还原正确，关闭压缩时走明文 |

## 7. 有意不做的事

- **不做文件下载**（断点续传 / 分片 / 进度 / 调度）：那属于 `selineDownload`，
  本库只提供它需要的流式响应与连接复用原语。
- **不做异步/事件循环**：仓颉侧并发用 `spawn` + `sendAll`，不引入额外调度层。
- **不做重定向的逐跳自定义策略**：跟随/不跟随由 `followRedirects` 控制，交给底层实现。

## 8. 下游迁移记录（demo 依赖链）

按「不保留旧名转发」的决定，demo 依赖链上的三个工程已迁移到新 API，现在整条链可编译：

| 工程 | 迁移内容 |
|------|----------|
| `selineDownload` | `LinderHttpClientPool/PooledRequest/RequestMethod/HttpHeader` → `HttpClient`+`HttpClientBuilder`/`RequestBuilder`/`Method`/`Headers`；分片与整包下载改用 `sendStream()` + `Response.stream()`；读取循环用 `try/finally { response.close() }` 兜住「取消/暂停 return」与异常路径，保证流式租约归还。库内重试收窄为「建连/传输失败再试一次」（`retryOnTimeout: false`、`retryOnStatus: []`），避免与其自身的 `maxRetries`+续传循环叠加 |
| `seline_minecraft_core` | `HttpQuick.get(...).getBodyString()` → `LinderHttp.get(...).text()`；`getBodyFile(filePath:, conflictMethod: OverWrite)` → `Response.saveTo(path, overwrite: true)`；`LinderHttpClient(...)` → `LinderHttp.get(url, headers:, timeouts:)`；`HttpHeader` → `Headers`；`LinderHttpResponse` → `Response` |
| `demo` | `HttpQuick.head(url).status` → `LinderHttp.head(url).status` |

### 端到端校验：多分片下载 + 一次我自己踩的坑（更正记录）

用本地测试服务器（HEAD + Range 探测 + 4 分片）校验 `selineDownload` 的多分片路径，结论是**正确**的：

- 服务器按 `bytes=0-527373 / 527374-1054747 / 1054748-1582121 / 1582122-2109496` 收到 4 个不重叠请求；
- 4 个分片各读到 527374 / 527374 / 527374 / 527375 字节，合计 2109497；
- 合并后文件 2109497 字节，**逐字节与期望一致**。

排查过程中曾出现过「文件偏大」（同一 2.1MB 目标得到 2601017 / 2740281 / 3691620 / 5273744 字节）。
当时的判断（怀疑 `selineDownload` 分片合并有缺陷）是**错误的**，真正原因是**我的测试服务器写错了 Range**：
只解析 `start` 而忽略 `end`，于是每个分片请求都被从 `startPos` 一直发到文件结尾。
四个分片的实际收字节数 2109497 + 1582123 + 1054749 + 527375 **正好等于** 5273744，
而合并结果的前 2109497 字节完全正确 —— 现象与根因完全吻合。客户端只是如实写盘并按序合并。

对应的两点修正：

1. 测试服务器的 Range 处理改为同时尊重起止位置（`demo/http_demo/src/server.cj` 同步修正，避免以后再被同一个坑误导）；
2. 顺带修掉 `selineDownload` 里一个真实小隐患：`checkRangeSupport()` 的 `Range: bytes=0-0` 探测响应只读头、从不消费正文。
   对规矩的服务器它只有 1 字节（自动落地，无害）；但对**无视 Range 直接回整个文件**的 CDN（这在现实中存在），
   正文会超过自动落地阈值而变成流式租约，不读就一直占着连接池槽位。现在显式 `testResponse.close()`（幂等），两种情况都不再留未归还租约。
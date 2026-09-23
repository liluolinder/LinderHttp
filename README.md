# LinderHttp 2.0 — 仓颉 HTTP 客户端库

> 按主流 HTTP 客户端（OkHttp / axios / requests / httpx / reqwest）的思路重新设计，
> 实现全部重写：**长连接复用 + 每 host 连接池 + 并发闸门 + 指数退避重试 + 一行式便捷 API**。

```cangjie
import linderHttp.*

// 一行搞定
let text = LinderHttp.text("https://example.com/")

// 需要精细控制时：客户端 + 链式请求
let client = HttpClientBuilder()
    .maxConnectionsPerHost(32)
    .retry(RetryPolicy.robust())
    .build()
let response = client.request(Method.Post, "https://api.example.com/v1/items")
    .jsonObject(payload)
    .bearer(token)
    .query("verbose", "1")
    .send()
println("${response.status} ${response.statusText}")
println(response.text())
client.close()
```

## 特性一览

| 能力 | 说明 |
|------|------|
| 长连接复用 | 每个 host 只建一个底层连接组，连接在组内复用（实测：同 host 连续 6 次请求，建连 1 次、复用 5 次） |
| 连接池 | 每 host 连接数上限、空闲超时回收、host 数上限与 LRU 淘汰、流式租约兜底回收 |
| 并发闸门 | 并发超过上限时**排队等待**，而不是抛出 `Too many connections`（实测：上限 2 + 12 并发全部成功） |
| 重试 | 只重试幂等方法；指数退避 + 抖动；遵守 `Retry-After`；默认对 429/502/503/504 重试 |
| 超时 | 连接 / 读 / 写 / 总预算四级；总预算会自动压低单次尝试的超时，真正约束整次请求 |
| 熔断 | 连续**传输层**失败达阈值后对该 host 快速失败（默认关闭，HealthPolicy 开启；冷却后放行探测，成功即恢复） |
| 透明解压 | 声明 `Accept-Encoding` 并自行解压 gzip/deflate（底层不会自动解压） |
| 请求目标编码 | 修复底层「把 `%20` 解码成空格再上线」的缺陷，中文 / 空格 / `&` / `=` 都能正确送达 |
| 便捷函数 | 一行式 `LinderHttp.text/json/bytes/post/...`、链式 `RequestBuilder`、`sendAll` 并发、`getAll` |
| 可观测性 | `PoolStats`（建组 / 复用 / 回收 / 重试计数）+ `EventListener`（含连接创建 / 复用 / 回收事件） |
| 其它 | Cookie 自动管理、拦截器、multipart、WebSocket、默认校验证书（可显式信任所有证书） |

## 职责边界

- 本库只负责 **HTTP 客户端原语**：连接、池、重试、超时、编解码、便捷调用。
- **文件下载（断点续传、分片、进度、下载调度）不在本库**，由 `selineDownload` 基于本库的
  流式响应（`sendStream` / `Response.stream()` / `Response.saveTo`）实现。

## 环境与构建

- 仓颉工具链 1.2.0，依赖 `stdx`（需要配置 `CANGJIE_STDX_PATH`）。
- 构建：`cjpm build`

## 实例测试

测试工程在 `C:\Project\Cangjie\demo\http_demo`：自带本地测试服务器（避免公网抖动影响结论），
另有少量真实公网 smoke。

```
cd C:\Project\Cangjie\demo\http_demo
cjpm build
target\release\bin\main.exe          # 全部断言
$env:HTTP_DEMO_FILTER="core"         # 只跑长连接 / 连接池 / 稳定性
$env:HTTP_DEMO_FILTER="conv"         # 只跑便捷函数
$env:HTTP_DEMO_FILTER="ws"           # 只跑 WebSocket
```

## 目录结构

```
src/
├── reexport.cj            顶层包：public import linderHttp.http.*
└── http/
    ├── prelude.cj         包级导入中心
    ├── error.cj           HttpError / StatusError / ErrorKind
    ├── method.cj          Method 枚举
    ├── headers.cj         Headers（大小写不敏感、多值）
    ├── body.cj            请求体
    ├── multipart.cj       multipart/form-data
    ├── tls.cj             TlsOptions（系统 CA / TrustAll / 自定义 CA）
    ├── options.cj         Timeouts / Http2Options / PoolOptions / ClientConfig
    ├── retry.cj           RetryPolicy
    ├── pool.cj            连接池 + 并发闸门 + 回收
    ├── events.cj          EventListener / Interceptor / RetryEvent
    ├── cookie.cj          Cookie / CookieStore
    ├── request.cj         Request / RequestBuilder
    ├── response.cj        Response / 流式租约
    ├── client.cj          HttpClient / HttpClientBuilder / 发送管线
    ├── websocket.cj       WebSocket / WebSocketMessage
    └── facade.cj          LinderHttp 一行式入口
doc/
├── feature_api.md         API 参考
└── ARCHITECTURE.md        架构、设计取舍与实测结论
```

# LinderHttp API 参考

## 目录
- [1. 包结构概览](#1-包结构概览)
- [2. 枚举类型](#2-枚举类型)
  - [2.1 ConflictMethod](#21-conflictmethod)
  - [2.2 RequestBody](#22-requestbody)
  - [2.3 RequestMethod](#23-requestmethod)
  - [2.4 RequestUrl](#24-requesturl)
- [3. 工具函数](#3-工具函数)
  - [3.1 defaultTSLConfig()](#31-defaulttslconfig)
  - [3.2 export2File](#32-export2file)
  - [3.3 StringExport 扩展接口](#33-stringexport-扩展接口)
- [4. 核心类](#4-核心类)
  - [4.1 LinderHttp](#41-linderhttp)
    - [4.1.1 属性](#411-属性)
    - [4.1.2 构造方法](#412-构造方法)
    - [4.1.3 链式配置方法](#413-链式配置方法)
    - [4.1.4 发送请求](#414-发送请求)
  - [4.2 LinderHttpHeader](#42-linderhttpheader)
    - [4.2.1 构造方法](#421-构造方法)
    - [4.2.2 方法](#422-方法)
  - [4.3 LinderHttpResponse](#43-linderhttpresponse)
    - [4.3.1 属性](#431-属性)
    - [4.3.2 计算属性](#432-计算属性)
    - [4.3.3 方法](#433-方法)
  - [4.4 LinderIntercept](#44-linderintercept)
    - [4.4.1 Intercept 实现类](#441-intercept-实现类)

---

## 1. 包结构概览

| 包名 | 主要功能 |
|------|----------|
| `linderHttp.commons` | 公共枚举类型定义（冲突处理、请求体、请求方法、请求URL） |
| `linderHttp.utils` | 工具函数和扩展方法（文件导出、TLS配置等） |
| `linderHttp` | 核心HTTP客户端类、响应类、拦截器接口等 |

---

## 2. 枚举类型

### 2.1 ConflictMethod
定义文件冲突处理策略。

| 枚举值 | 说明 |
|--------|------|
| `OVER_WRITE` | 直接覆盖已存在的文件 |
| `HARMONY` | 自动生成新文件名（格式：`原文件名(序号).扩展名`） |

---

### 2.2 RequestBody
表示HTTP请求体的不同类型。

| 枚举值 | 说明 |
|--------|------|
| `STRING(String)` | 字符串类型 |
| `INPUT_STREAM(InputStream)` | 输入流类型 |
| `BYTE_ARRAY(Array<Byte>)` | 字节数组类型 |
| `OBJECT(DataModel)` | 数据模型对象 |
| `JSON(JsonObject)` | JSON对象 |
| `URLENCODED(Form)` | URL编码表单数据 |

**静态构造方法：**
```Cangjie
// STRING 类型请求体
RequestBody.from(v: String)  
   
// INPUT_STREAM 类型请求体   
RequestBody.from(v: InputStream)   

// BYTE_ARRAY 类型请求体
RequestBody.from(v: Array<Byte>)   

// URLENCODED 类型请求体
RequestBody.from(v: Form)          

// OBJECT 类型请求体
RequestBody.from(v: DataModel)     

// JSON 类型请求体
RequestBody.from(v: JsonObject)
```

---

### 2.3 RequestMethod
表示HTTP请求方法，实现`ToString`接口。

| 枚举值 | 字符串值 |
|--------|----------|
| `GET` | "GET" |
| `POST` | "POST" |
| `HEAD` | "HEAD" |
| `PUT` | "PUT" |
| `PATCH` | "PATCH" |
| `DELETE` | "DELETE" |
| `COPY` | "COPY" |
| `OPTION` | "OPTION" |
| `LINK` | "LINK" |
| `UNLINK` | "UNLINK" |
| `PUGRE` | "PUGRE" |
| `LOCK` | "LOCK" |
| `UNLOCK` | "UNLOCK" |
| `PROPFIND` | "PROPFIND" |
| `VIEW` | "VIEW" |
| `CUSTOM(String)` | 自定义字符串 |

---

### 2.4 RequestUrl
表示请求URL的类型。实现`ToString`接口。

| 枚举值 | 说明 |
|--------|------|
| `STRING(String)` | 字符串类型的URL |
| `URL(URL)` | URL对象类型 |

**静态构造方法：**
```Cangjie
RequestUrl.from(v: String)  //  STRING 类型
RequestUrl.from(v: URL)     //  URL 类型
```

---

## 3. 工具函数

### 3.1 defaultTSLConfig()
返回默认的TLS客户端配置，验证模式为`TrustAll`。

```Cangjie
public func defaultTSLConfig(): TlsClientConfig
```

---

### 3.2 export2File
将内容导出到文件，支持冲突处理策略。

```Cangjie
public func export2File(
    content!: String, 
    filePath!: Path, 
    conflictMethod!: ConflictMethod = ConflictMethod.HARMONY
)

public func export2File(
    content!: InputStream, 
    filePath!: Path, 
    conflictMethod!: ConflictMethod = ConflictMethod.HARMONY
)
```

---

### 3.3 StringExport 扩展接口
为`String`类型添加文件导出功能。

```Cangjie
public interface StringExport {
    func export2File(filePath!: Path, conflictMethod!: ConflictMethod): Unit
    func exportJson2File(filePath!: Path, conflictMethod!: ConflictMethod): Unit
}
```


## 4. 核心类

### 4.1 LinderHttp
HTTP客户端主类，支持链式调用。

#### 4.1.1 属性

| 属性名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `url` | `RequestUrl` | `RequestUrl.from("")` | 请求URL |
| `httpHeader` | `LinderHttpHeader` | 新建实例 | HTTP头部容器 |
| `tlsConfig` | `TlsClientConfig` | `defaultTSLConfig()` | TLS配置 |
| `method` | `String` | `"GET"` | HTTP方法 |
| `requestBody` | `?RequestBody` | `None` | 请求体 |
| `autoRedirect` | `Bool` | `true` | 是否自动重定向 |
| `readTimeout` | `Duration` | `15秒` | 读取超时 |
| `writeTimeout` | `Duration` | `15秒` | 写入超时 |
| `initialWindowSize` | `UInt32` | `65535` | HTTP/2流控窗口初始大小 |
| `enablePush` | `Bool` | `true` | 是否启用HTTP/2服务器推送 |
| `headerTableSize` | `UInt32` | `4096` | HPACK动态表初始大小 |
| `httpProxy` | `String` | `""` | HTTP代理（环境变量优先） |
| `httpsProxy` | `String` | `""` | HTTPS代理（环境变量优先） |

#### 4.1.2 构造方法
```Cangjie
public init(
    url!: RequestUrl,
    domin!: String = "",
    tlsConfig!: ?TlsClientConfig = None,
    linderHttpHeader!: ?LinderHttpHeader = None,
    httpHeaders!: ?HttpHeaders = None,
    intercept!: ?LinderIntercept = None,
    method!: RequestMethod = RequestMethod.GET,
    requestBody!: ?RequestBody = None,
    autoRedirect!: Bool = true,
    readTimeout!: Duration = Duration.second * 15,
    writeTimeout!: Duration = Duration.second * 15,
    initialWindowSize!: UInt32 = 65535,
    enablePush!: Bool = true,
    headerTableSize!: UInt32 = 4096,
    httpProxy!: String = "",
    httpsProxy!: String = ""
)
```

#### 4.1.3 链式配置方法

##### `setUrl(v: RequestUrl/String/URL): LinderHttp`
设置请求URL并自动更新TLS域名。

**参数：**
- `v` - 目标URL，可以是`RequestUrl`枚举、`String`类型或`URL`对象

**说明：**
调用此方法将同步更新TLS配置的域名（如果`tlsConfig.domain`未设置）。

**注意事项：**
- 如果`tlsconfig`已设置`domin`则无操作
- 该方法支持链式调用

**示例：**
```Cangjie
http.setUrl("https://api.example.com")
    .setUrl(RequestUrl.from("https://api.example.com"))
 ```

---

##### `setHeader(v: HttpHeaders/LinderHttpHeader): LinderHttp`
设置HTTP头部（覆盖式更新）。

**参数：**
- `v` - HTTP头容器，可以是标准`HttpHeaders`或专属`LinderHttpHeader`

**说明：**
- 此操作将覆盖现有`LinderHttpHeader`
- 两种类型的参数对应不同行为：
  - `HttpHeaders`：调用`httpHeader.setALL(v)`进行批量替换
  - `LinderHttpHeader`：直接替换整个头部容器

**警告：**
- 使用`LinderHttpHeader`参数会完全替换现有头部信息

**示例：**
```Cangjie
// 使用标准HttpHeaders
var headers = HttpHeaders()
headers.set("Content-Type", "application/json")
http.setHeader(headers)

// 使用LinderHttpHeader
var linderHeaders = LinderHttpHeader()
linderHeaders.add(key: "Content-Type", value: "application/json")
http.setHeader(linderHeaders)
```

---

##### `setMehod(v: RequestMethod/String): LinderHttp`
设置HTTP请求方法。

**参数：**
- `v` - 请求方法，可以是`RequestMethod`枚举或自定义字符串

**说明：**
- 使用`RequestMethod`枚举版本：内部自动转换为字符串形式存储，保证方法名合法性
- 使用字符串版本：需自行确保方法名符合HTTP规范

**注意事项：**
- 优先使用`RequestMethod`枚举版本保证方法名合法性
- 非标准方法可能导致请求失败
- 默认方法为`GET`

**示例：**
```Cangjie
// 使用枚举
http.setMehod(RequestMethod.POST)

// 使用自定义方法
http.setMehod("CUSTOM_METHOD")
```

---

##### `setIntercept(v: LinderIntercept): LinderHttp`
设置HTTP拦截器。

**参数：**
- `v` - 继承`LinderIntercept`接口的拦截器对象

**说明：**
- 拦截器可以监听请求发送、响应接收、异常处理等事件
- 默认值为`None`（未初始化状态）

**示例：**
```Cangjie
var intercept = Intercept(
    requestL : { http => println("发送请求") },
    responseL : { res => println("收到响应: ${res.status}") })
http.setIntercept(intercept)

```

---

##### `setDomin(v: String): LinderHttp`
自定义TLS握手域名。

**参数：**
- `v` - 域名标识字符串

**重要说明：**
- 此设置会被后续`setUrl()`调用覆盖
- 如需自定义域名，请在`setUrl()`之后调用此方法

**示例：**
```Cangjie
http.setUrl("https://api.example.com")
    .setDomin("custom-domain.com") // 覆盖URL解析的域名
```

---

##### `setAutoRedirect(v: Bool): LinderHttp`
配置重定向策略。

**参数：**
- `v` - 是否自动重定向，`true`为启用，`false`为禁用

**默认值：**
- `true`（启用自动重定向）

**示例：**
```Cangjie
http.setAutoRedirect(false) // 禁用自动重定向
```

---

##### `setReadTimeout(v: Duration): LinderHttp`
设置读取响应超时阈值。

**参数：**
- `v` - 超时时间，单位为`Duration`

**默认值：**
- `15秒`（`Duration.second * 15`）

**示例：**
```Cangjie
http.setReadTimeout(Duration.second * 30) // 设置为30秒
```

---

##### `setWriteTimeout(v: Duration): LinderHttp`
设置发送请求超时阈值。

**参数：**
- `v` - 超时时间，单位为`Duration`

**默认值：**
- `15秒`（`Duration.second * 15`）

**示例：**
```Cangjie
http.setWriteTimeout(Duration.second * 30) // 设置为30秒
```

---

##### `setBody(v: RequestBody/String/InputStream/Array<Byte>/DataModel/JsonObject/Form): LinderHttp`
设置请求附带数据。

**参数：**
- `v` - 请求体数据，支持多种类型

**支持的类型：**
1. `RequestBody`枚举：完整封装的各种请求体类型
2. `String`：字符串数据，自动包装为`RequestBody.STRING`
3. `InputStream`：输入流数据，自动包装为`RequestBody.INPUT_STREAM`
4. `Array<Byte>`：字节数组数据，自动包装为`RequestBody.BYTE_ARRAY`
5. `DataModel`：数据模型对象，自动包装为`RequestBody.OBJECT`
6. `JsonObject`：JSON对象，自动包装为`RequestBody.JSON`
7. `Form`：表单数据，自动包装为`RequestBody.URLENCODED`

**默认值：**
- `None`（不附带数据）

**示例：**
```Cangjie
// 字符串数据
http.setBody("Hello World")

// 表单数据
var form = Form()
form.add("username", "admin")
form.add("password", "123456")
http.setBody(form)
```

---

##### `setInitialWindowSize(v: UInt32): LinderHttp`
配置客户端HTTP/2流控窗口初始值。

**参数：**
- `v` - 流控窗口大小，类型为`UInt32`

**取值范围：**
- `0` 至 `2^31 - 1`

**默认值：**
- `65535`

**示例：**
```Cangjie
http.setInitialWindowSize(131072) // 设置为128KB
```

---

##### `setEnablePush(v: Bool): LinderHttp`
配置客户端HTTP/2是否支持服务器推送。

**参数：**
- `v` - 是否启用服务器推送，`true`为启用，`false`为禁用

**默认值：**
- `true`（启用服务器推送）

**示例：**
```Cangjie
http.setEnablePush(false) // 禁用HTTP/2服务器推送
```

---

##### `setHeaderTableSize(v: UInt32): LinderHttp`
配置客户端HTTP/2 HPACK动态表初始值。

**参数：**
- `v` - 动态表大小，类型为`UInt32`

**默认值：**
- `4096`

**示例：**
```Cangjie
http.setHeaderTableSize(8192) // 设置为8KB
```

---

##### `setHttpProxy(v: String): LinderHttp`
设置客户端HTTP代理。

**参数：**
- `v` - HTTP代理地址字符串

**默认行为：**
- 默认使用系统环境变量`http_proxy`的值

**示例：**
```Cangjie
http.setHttpProxy("http://proxy.example.com:8080")
```

---

##### `setHttpsProxy(v: String): LinderHttp`
设置客户端HTTPS代理。

**参数：**
- `v` - HTTPS代理地址字符串

**默认行为：**
- 默认使用系统环境变量`https_proxy`的值

**示例：**
```Cangjie
http.setHttpsProxy("https://proxy.example.com:8443")
```

---

##### `clearBody(): LinderHttp`
清空请求附带数据。

**说明：**
- 将`requestBody`属性设置为`None`
- 用于在复用HTTP客户端实例时清除之前的请求体

**示例：**
```Cangjie
http.setBody("Data to send")
    .send()
    .clearBody() // 清除请求体，准备下一次请求
```

---

##### `setDefaultHeader(): LinderHttp`
设置默认请求头。

**说明：**
- 将`httpHeader`属性重置为新的`LinderHttpHeader`实例
- 新实例会预置浏览器头信息：
  - `Sec-ch-ua`
  - `Sec-ch-ua-platform`
  - `User-agent`

**示例：**
```Cangjie
http.setDefaultHeader() // 重置为默认浏览器头部
```

---

##### `destory(): LinderHttp`
取消请求并清理资源。

**说明：**
- 如果HTTP客户端已创建，则关闭连接
- 将`httpClinet`属性设置为`None`
- 用于手动释放网络连接资源

**注意事项：**
- 调用此方法后，需要重新构建客户端才能发送新请求

**示例：**
```Cangjie
http.send()
    .destory() // 关闭连接，释放资源
```

### 4.1.4 发送请求

#### `send(needSetDefaultHeader: Bool = false): LinderHttpResponse`

##### 方法说明

发送HTTP请求并获取响应。

**参数：**
- `needSetDefaultHeader` - 是否在发送后设置为默认请求头，默认为`false`

**返回值：**
- `LinderHttpResponse` - 请求返回体对象



#### 功能描述

#### 请求发送流程
1. **拦截器预处理**：如果设置了`linderIntercept`，先调用`request()`方法
2. **客户端配置**：使用当前配置构建HTTP客户端
3. **请求构建**：根据URL、方法、头部、请求体等参数构建HTTP请求
4. **内容类型自动设置**：如果请求体存在且未设置`content-type`头部，根据请求体类型自动设置：
   - `STRING` → `"text/xml"`
   - `BYTE_ARRAY` → `"application/octet-stream"`
   - `INPUT_STREAM` → `"application/octet-stream"`
   - `URLENCODED` → `"application/x-www-form-urlencoded"`
   - `OBJECT` → `"application/json"`
   - `JSON` → `"application/json"`
5. **发送请求**：通过HTTP客户端发送请求并接收响应
6. **拦截器后处理**：如果设置了`linderIntercept`，调用`response()`方法

##### 异常处理
- 请求构建过程中的异常会触发拦截器的`requestError()`方法
- 请求发送过程中的异常会触发拦截器的`requestError()`方法
- 所有异常都会被捕获，不会抛出到调用方

##### 响应处理
- 响应被封装为`LinderHttpResponse`对象返回
- 响应体流(`body`)只能读取一次，重复读取会返回空或异常
- 响应头可以通过`LinderHttpResponse`的属性和方法访问

---

### 4.2 LinderHttpHeader
HTTP头部管理类。

#### 4.2.1 构造方法
```Cangjie
public init()  // 预置浏览器头部信息
```

#### 4.2.2 方法

##### `setALL(v: HttpHeaders): LinderHttpHeader`

批量替换HTTP头。

**参数：**
- `v` - 新的`HttpHeaders`对象

**返回值：**
- `LinderHttpHeader` - 当前对象实例（支持链式调用）

**说明：**
此操作将**完全覆盖**现有头信息。原有的所有头部字段都会被清除，替换为传入的`HttpHeaders`对象中的所有头部。

**注意事项：**
- 操作不可逆，原有头部信息将丢失
- 传入的`HttpHeaders`对象会直接赋值给内部的`httpHeader`属性

---

##### `set(key!: String, value!: String): LinderHttpHeader`

设置单一头字段（覆盖模式）。

**参数：**
- `key` - 头字段名（如`"Content-Type"`）
- `value` - 头字段值（如`"application/json"`）

**返回值：**
- `LinderHttpHeader` - 当前对象实例（支持链式调用）

**行为说明：**
- 若字段已存在则覆盖原有值
- 若字段不存在则创建新字段
- 此方法只设置单个值，即使该头部支持多个值也会被替换

**适用场景：**
- 设置唯一值头部，如`Content-Type`、`Authorization`
- 需要确保头部只有一个值时

---

##### `add(key!: String, value!: String): LinderHttpHeader`

添加头字段。

**参数：**
- `key` - 头字段名（如`"Accept"`）
- `value` - 头字段值（如`"text/html"`）

**返回值：**
- `LinderHttpHeader` - 当前对象实例（支持链式调用）

**行为说明：**
- 若字段不存在则创建新字段
- 若字段已经存在，将在其对应的值列表中添加`value`
- 允许同一个头部字段有多个值

**适用场景：**
- 需要添加多个值的头部，如`Accept`、`Cache-Control`
- 不希望覆盖原有值的情况

---

##### `delete(key: String): LinderHttpHeader`

删除头字段。

**参数：**
- `key` - 要删除的字段名

**返回值：**
- `LinderHttpHeader` - 当前对象实例（支持链式调用）

**说明：**
- 若字段不存在则无操作
- 删除指定键的所有值

---

##### `get(key: String): Collection<String>`

获取头字段值集合。

**参数：**
- `key` - 头字段名

**返回值：**
- `Collection<String>` - 值集合（可能为空集合）

**特性说明：**
- 返回值为不可变集合
- 对于多值头字段，返回所有值的集合
- 如果字段不存在，返回空集合

---

##### `getFirst(key: String): ?String`

获取头字段首个值。

**参数：**
- `key` - 头字段名

**返回值：**
- `String` - 字段的第一个值，不存在返回`None`

**适用场景：**
- 单值头字段快速访问（如`Content-Type`）
- 只需要获取多值头部的第一个值时

**注意事项：**
- 如果字段不存在，返回None
- 对于多值头部，只返回第一个值

---

##### `isEmpty(): Bool`

检查头是否为空。

**返回值：**
- `Bool` - 当不含任何头字段时返回`true`

**说明：**
- 判断内部`HttpHeaders`容器是否为空
- 包括预置的默认头部也会被计算在内

---

##### `printlnAll(): Unit`

打印所有头部到控制台。

**输出格式：**
- 每行格式：`HeaderName: [value1,value2]`
- 对于多值头部，所有值会显示在方括号内

**适用场景：**
- 调试时快速检查响应头
- 查看当前设置的所有头部信息

---

##### 预置头部信息

创建`LinderHttpHeader`实例时会自动添加以下浏览器头部：

| 头部字段 | 值 |
|----------|-----|
| `Sec-ch-ua` | `"Chromium";v="142", "Microsoft Edge";v="142", "Not_A Brand";v="99"` |
| `Sec-ch-ua-platform` | `"Windows"` |
| `User-agent` | `Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0` |


---

### 4.3 LinderHttpResponse
HTTP响应封装类。

#### 4.3.1 属性
| 属性名 | 类型 | 说明 |
|--------|------|------|
| `body` | `?InputStream` | 响应体数据流（只能读取一次） |
| `bodySize` | `?Int64` | 响应体大小 |
| `status` | `UInt16` | HTTP状态码 |
| `headers` | `HttpHeaders` | 响应头集合 |
| `isPersistent` | `Bool` | 连接是否保持 |
| `request` | `?HttpRequest` | 关联的请求对象 |

#### 4.3.2 Prop

##### `location: ?Array<String>`

**重定向目标地址**

**类型：** `?Array<String>`

**说明：**
从`Location`响应头中提取的重定向地址数组。当HTTP响应包含重定向状态码（如301、302、307等）时，服务器通常会在`Location`头部中指定重定向的目标URL。

**返回值说明：**
- `None` - 表示响应中不包含`Location`头部
- `Some(Array<String>)` - 包含1-N个URL地址的数组

**注意事项：**
- 一个响应可能包含多个`Location`头部，所有值都会被收集到数组中
- 即使只有一个重定向地址，也会以单元素数组形式返回
- 需要检查响应状态码是否属于重定向范围（300-399）

---

##### `contentType: ?Array<String>`

**内容类型标识**

**类型：** `?Array<String>`

**说明：**
从`Content-Type`响应头中提取的MIME类型数组。该头部指定了响应体的媒体类型和字符编码等信息。

**返回值说明：**
- `None` - 表示响应中不包含`Content-Type`头部
- `Some(Array<String>)` - 包含1-N个内容类型标识的数组

**格式示例：**
- `["application/json; charset=utf-8"]`
- `["text/html; charset=UTF-8"]`
- `["application/xml", "text/plain"]` （如果服务器发送了多个Content-Type头部）

**常见MIME类型：**
- `application/json` - JSON数据
- `application/xml` - XML数据
- `text/html` - HTML文档
- `text/plain` - 纯文本
- `application/octet-stream` - 二进制数据
- `image/jpeg` - JPEG图片
- `application/pdf` - PDF文档

---

##### `setCookie: ?Array<String>`

**服务端设置的Cookie信息**

**类型：** `?Array<String>`

**说明：**
从`Set-Cookie`响应头中提取的Cookie字符串数组。服务器使用此头部在客户端（浏览器）设置或更新Cookie。

**返回值说明：**
- `None` - 表示响应中不包含`Set-Cookie`头部
- `Some(Array<String>)` - 包含1-N个Cookie字符串的数组

#### 4.3.3 方法

##### `getHeader(header: String): ?Array<String>`

获取指定响应头的值。

**参数：**
- `header` - 头部字段名（不区分大小写）

**返回值：**
- `?Array<String>` - 头部值数组（同名字段多个值时按顺序返回），`None`表示该头部不存在

**说明：**
此方法用于获取任意响应头部的值，支持多值头部。相比`location`、`contentType`、`setCookie`等特定属性，此方法可以获取任何自定义或标准头部。

---

##### `getBodyStream(): InputStream`

获取原始响应体流。

**返回值：**
- `InputStream` - 未解码的二进制数据流

**说明：**
返回原始的响应体输入流，允许手动控制数据读取过程。这是最底层的响应体访问方式，其他`getBody*()`方法都基于此流实现。

**重要限制：**
- **响应体流只能读取一次**
- 读取后流位置将移动到末尾
- 调用两次会返回空或异常报错

---

##### `getBodyString(): String`

获取响应体字符串。

**返回值：**
- `String` - 按默认编码解码的字符串

**异常：**
- 会触发异常，详见`std.io.*`、`std.fs.*`
- 如果响应体为空或读取失败会抛出异常
- 编码相关问题也可能导致异常

**说明：**
将响应体按默认字符编码（通常为UTF-8或系统默认编码）解码为字符串。适用于文本响应（HTML、JSON、XML、纯文本等）。

---

##### `getBodyJsonString(): String`

获取JSON格式字符串。

**返回值：**
- `String` - 格式化后的JSON字符串

**说明：**
此方法将响应体解析为JSON，然后重新格式化为标准JSON字符串。适用于确保JSON格式正确或美化输出的场景。

**处理流程：**
1. 调用`getBodyString()`获取原始字符串
2. 使用`JsonValue.fromStr()`解析为`JsonValue`
3. 使用`toJsonString()`格式化为标准JSON

**适用场景：**
- 调试时查看格式化JSON
- 需要确保JSON格式规范
- 将响应保存为标准化JSON文件

---

##### `getBodyJsonValue(): JsonValue`

获取JsonValue对象。

**返回值：**
- `JsonValue` - 解析后的JSON值对象

**说明：**
将响应体解析为通用的`JsonValue`对象，可以表示JSON的任何类型（对象、数组、字符串、数字、布尔、null）。

---

##### `getBodyJsonObject(): JsonObject`

获取JsonObject对象。

**返回值：**
- `JsonObject` - 解析后的JSON对象

**异常：**
- 如果响应体不是有效的JSON对象格式会抛出异常

---

##### `getBodyDataModel(): DataModel`

获取DataModel对象。

**返回值：**
- `DataModel` - 序列化后的数据模型对象

**说明：**
将JSON响应体反序列化为`DataModel`对象。便于序列化与反序列化

---

##### `getBodyByteBuffer(): ByteBuffer`

获取响应体字节缓冲。

**返回值：**
- `ByteBuffer` - 内存连续的二进制数据缓冲

**异常：**
- 会触发异常，详见`std.io.*`、`std.fs.*`

---

##### `getBodyFile(filePath!: Path, conflictMethod!: ConflictMethod): Unit`

将响应体保存为文件。

**参数：**
- `filePath` - 目标文件路径（需包含文件名）
- `conflictMethod` - 文件冲突处理策略，默认`ConflictMethod.HARMONY`

**异常：**
- 会触发异常，详见`std.io.*`、`std.fs.*`

**冲突策略说明：**
- **`ConflictMethod.HARMONY`**（默认）：自动重命名（如`file.txt` → `file(1).txt`）
- **`ConflictMethod.OVER_WRITE`**：覆盖现有文件

**文件冲突处理示例：**
```Cangjie
// 如果 downloads/file.txt 已存在
response.getBodyFile(Path("downloads/file.txt"), ConflictMethod.HARMONY)
// 会保存为 downloads/file(1).txt

// 如果 downloads/file.txt 已存在
response.getBodyFile(Path("downloads/file.txt"), ConflictMethod.OVER_WRITE)
// 会直接覆盖原文件
```
---

##### `printHeaders(): Unit`

打印响应头到控制台。

**输出格式：**
- 每行格式：`HeaderName: [value1,value2]`
- 对于多值头部，所有值显示在方括号内

---

###### 重要注意事项

1. **响应体单次读取**：
   - 所有`getBody*()`方法都基于同一个`InputStream`
   - 调用任意一个后，其他方法可能无法正确读取
   - 建议根据需要只调用一个方法

2. **异常处理**：
   - 所有方法都可能抛出I/O异常
   - 建议使用try-catch包装
   - JSON相关方法在格式错误时也会抛出异常

---

### 4.4 LinderIntercept
HTTP请求/响应拦截器接口。

```Cangjie
public interface LinderIntercept {
    func request(http: LinderHttp): Unit
    func requestError(error: Exception): Unit
    func response(res: LinderHttpResponse): Unit
    func responseError(error: Exception): Unit
}
```

#### 方法详解

##### 1. `request(http: LinderHttp): Unit`
**请求发送前拦截函数**

###### 触发时机
HTTP请求参数组装完成，即将发起网络请求前

###### 参数说明
| 参数名 | 类型 | 说明 |
|--------|------|------|
| `http` | `LinderHttp` | 当前HTTP请求对象实例 |

###### 功能说明
- 在请求实际发送到服务器之前被调用
- 可以访问和修改请求配置（URL、头部、请求体等）
- 适合用于添加认证信息、记录请求日志、参数验证等

---

##### 2. `requestError(error: Exception): Unit`
**请求前阶段异常拦截函数**

###### 触发时机
请求构建中抛出异常时

###### 参数说明
| 参数名 | 类型 | 说明 |
|--------|------|------|
| `error` | `Exception` | 捕获的异常对象实例 |

###### 功能说明
- 处理请求构建阶段的异常
- URL解析失败、请求体序列化等问题
- 适合用于错误记录、重试逻辑、降级处理等

---

##### 3. `response(res: LinderHttpResponse): Unit`
**响应接收后拦截函数**

###### 触发时机
成功接收到HTTP响应后

###### 参数说明
| 参数名 | 类型 | 说明 |
|--------|------|------|
| `res` | `LinderHttpResponse` | HTTP响应对象实例 |

###### 功能说明
- 在响应被返回给调用者之前被调用
- 可以访问响应状态码、头部、响应体等

###### 注意事项
- 响应体流只能读取一次，避免在此多次读取
- 修改响应对象可能会影响调用者接收到的响应

---

##### 4. `responseError(error: Exception): Unit`
**响应处理异常拦截函数**

##### 触发时机
请求阶段及响应体解析过程中抛出异常时

##### 参数说明
| 参数名 | 类型 | 说明 |
|--------|------|------|
| `error` | `Exception` | 捕获的异常对象实例 |

---

###### 4.4.1 Intercept 实现类
```Cangjie
public class Intercept <: LinderIntercept {
    public init(
        let requestL: (LinderHttp) -> Unit = {_ ->},
        let requestErrorL: (Exception) -> Unit = {_ ->},
        let responseL: (LinderHttpResponse) -> Unit = {_ ->},
        let responseErrorL: (Exception) -> Unit = {_ ->}
    )
}
```
**作用：**
- 通过lamdba表达式快捷设置拦截器，使用方式详见example
---

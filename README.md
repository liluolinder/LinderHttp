# LinderHttp

## 📖 介绍

LinderHttp 是一个轻量级 HTTP 客户端库，提供请求构建、响应解析、拦截器等核心功能，帮助开发者高效处理网络请求。

## ✨ 项目特性

- 🔧 全项目采用**仓颉语言**开发
- ⚡ 内置多种便捷请求函数与请求体解析工具
- 🛡️ 支持拦截器机制，可动态修改请求/响应
- 📦 提供简洁的请求头管理类与工具函数

## 📚 API 说明

所有核心接口、枚举和工具函数详见：\
👉  [API参考](./doc/api.md)

## 🍴 食用方式

### 1️⃣ 依赖引入

在 `cjpm.toml` 中添加：

```toml
[dependencies]
linderHttp = { git = "https://gitcode.com/LiquidStudio/LinderHttp.git" }
```

### 2️⃣ 安装与构建

```bash
cjpm update  # 🔄 更新依赖
cjpm build   # 🛠️ 构建项目
```

## 🚀 功能示例

### GET请求

```Cangjie
import linderHttp.*
import linderHttp.utils.*
import linderHttp.commons.*

main(): Int64 {
    let test: LinderHttp = LinderHttp(
        url: RequestUrl.from("http://example.com"),
        method: RequestMethod.GET,
    )
    let res = test.send()
    res.status |> println //输出响应状态
    return 0
}
```

### POST请求-请求体为JSON(application/json)

- 示例JSON

```Json
{
  "name": "张三",
  "age": "18"
}
```

- 请求方式

```Cangjie
import linderHttp.*
import linderHttp.utils.*
import linderHttp.commons.*
import stdx.encoding.json.*

main(): Int64 {

    //JsonObject构造
    var body: JsonObject = JsonObject()
    body.put('name', JsonString("张三"))
    body.put('age', JsonString("18"))
    body.toJsonString() |> println

    //字符串构造
    body = JsonValue.fromStr(
        #"{
            "name": "张三",
            "age": "18"
        }"#).asObject()

    let test: LinderHttp = LinderHttp(
        url: RequestUrl.from("http://example.com"),
        method: RequestMethod.POST,
        requestBody: RequestBody.from(body)
    )
    let res = test.send()
    res.status |> println //输出响应状态
    return 0
}
```

### POST请求-请求体为Form(application/x-www-form-urlencoded)

- 示例Form

```
name=%E5%BC%A0%E4%B8%89&age=18
```

- 请求方式

```Cangjie
import linderHttp.*
import linderHttp.utils.*
import linderHttp.commons.*
import stdx.encoding.url.*

main(): Int64 {
    //Form构造
    var body: Form = Form()
    body.add('name', "张三")
    body.add('age', "18")

    body.toEncodeString() |> println

    let test: LinderHttp = LinderHttp(
        url: RequestUrl.from("http://example.com"),
        method: RequestMethod.POST,
        requestBody: RequestBody.from(body)
    )
    let res = test.send()
    res.status |> println //输出响应状态
    return 0
}
```

### 拦截器(lambda构造)

```Cangjie
import linderHttp.*
import linderHttp.utils.*
import linderHttp.commons.*

main(): Int64 {
    let test: LinderHttp = LinderHttp(
        url: RequestUrl.from("http://example.com"),
        method: RequestMethod.GET,
        intercept: Intercept(
            requestL: {
                req: LinderHttp => req.url |> println //输出请求域名
            },
            requestErrorL: {
                err: Exception => '小笨蛋，请求出错了哦，错误信息为${err.message}' |> println
            },
            responseL: {
                res: LinderHttpResponse => res.status |> println //输出响应状态
            },
            responseErrorL: {
                err: Exception => '小笨蛋，请求出错了哦，错误信息为${err.message}' |> println
            },
            onStartReadL: {
                totalSize: Int64 => '文件总大小为${totalSize}' |> println
            },
            onReadProgressUpdateL: {
                singleReadSize: Int64, hasReadSize: Int64, totalSize: Int64 => '本次读取文件大小为${singleReadSize}, 已经读取了${hasReadSize}, 总大小为${totalSize}' |>
                    println
            },
            onReadEndL: {
              path:?Path  => '保存完成,保存地址为${path}' |> println
            }
        )
    )
    let res = test.send()
    res.status |> println //输出响应状态
    return 0
}
```

### 拦截器(自定义对象构造)

```Cangjie
import linderHttp.*
import linderHttp.utils.*
import linderHttp.commons.*

public class MyInterCept <: LinderIntercept {
    public func request(req: LinderHttp): Unit {
        req.url |> println //输出请求域名
    }

    public func requestError(error: Exception): Unit {
        '小笨蛋，请求出错了哦，错误信息为${error.message}' |> println
    }

    public func response(res: LinderHttpResponse): Unit {
        res.status |> println //输出响应状态
    }

    public func responseError(error: Exception): Unit {
        '小笨蛋，请求出错了哦，错误信息为${error.message}' |> println
    }

    public func onStartRead(totalSize: Int64): Unit {
        '文件总大小为${totalSize}' |> println
    }

    public func onReadProgressUpdate(singleReadSize: Int64, hasReadSize: Int64, totalSize: Int64): Unit {
       '本次读取文件大小为${singleReadSize}, 已经读取了${hasReadSize}, 总大小为${totalSize}' |> println
    }

    public func onReadEnd(path:?Path): Unit{
       '保存完成,保存地址为${path}' |> println
    }
}

main(): Int64 {
    let test: LinderHttp = LinderHttp(
        url: RequestUrl.from("http://example.com"),
        method: RequestMethod.GET,
        intercept: MyInterCept()
    )
    let res = test.send()
    res.status |> println //输出响应状态
    return 0
}
```

### 响应体操作

```Cangjie
import linderHttp.*
import linderHttp.utils.*
import linderHttp.commons.*

main(): Int64 {
    let test: LinderHttp = LinderHttp(
        url: RequestUrl.from("http://example.com"),
        method: RequestMethod.GET
    )
    let res = test.send()

    res.setCookie //获取响应头中 Set-Cookie 字段所有内容
    res.location //获取响应头中 location 字段所有内容
    res.contentType // 获取响应头中 contentType 字段所有内容

    /*
        一下为示例代码，getBodyXXX系列对body读取代码只能使用一个且只能使用一次
     */
    //将body以String类型返回
    res.getBodyString()
    //将body以JSONValue类型返回
    res.getBodyJsonValue()
    //将body以JsonObject类型返回
    res.getBodyJsonObject()
    //将body以JsonString类型返回
    res.getBodyJsonString()
    //将body输出文件
    res.getBodyFile(filePath: Path('./test'))
    //将body以InputStream类型返回
    res.getBodyStream()
    //将body以DataModel类型返回，方便序列化与反序列化
    res.getBodyDataModel()
    //将body以ByteBuffer类型返回
    res.getBodyByteBuffer()
    return 0
}
```

## ⚠️ 约束与限制

验证通过的运行环境：\
`Cangjie Version: 1.0.4 - Windows`

## 📜 开源协议

本项目采用  [Mulan PSL v2](./LICENSE) 许可
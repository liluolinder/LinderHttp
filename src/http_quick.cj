package linderHttp

import std.collection.*
import stdx.encoding.url.*

/**
 * LinderHttp便捷请求方法
 * 提供类似axios风格的快捷请求方法
 */
public class LinderHttpQuick {
    /**
     * 发送GET请求
     * @param url 请求URL
     * @return 响应对象
     */
    public static func get(url: String): LinderHttpResponse {
        LinderHttp(url: RequestUrl.from(url), method: RequestMethod.GET).send()
    }
    
    /**
     * 发送GET请求
     * @param url URL对象
     * @return 响应对象
     */
    public static func get(url: URL): LinderHttpResponse {
        LinderHttp(url: RequestUrl.from(url), method: RequestMethod.GET).send()
    }
    
    /**
     * 发送GET请求（带请求头）
     * @param url 请求URL
     * @param headers 请求头
     * @return 响应对象
     */
    public static func get(url: String, headers: HashMap<String, String>): LinderHttpResponse {
        LinderHttp(url: RequestUrl.from(url), method: RequestMethod.GET)
            .setHeader(headers)
            .send()
    }
    
    /**
     * 发送POST请求
     * @param url 请求URL
     * @param body 请求体
     * @return 响应对象
     */
    public static func post(url: String, body: String): LinderHttpResponse {
        LinderHttp(url: RequestUrl.from(url), method: RequestMethod.POST)
            .setBody(body)
            .send()
    }
    
    /**
     * 发送POST请求
     * @param url URL对象
     * @param body 请求体
     * @return 响应对象
     */
    public static func post(url: URL, body: String): LinderHttpResponse {
        LinderHttp(url: RequestUrl.from(url), method: RequestMethod.POST)
            .setBody(body)
            .send()
    }
    
    /**
     * 发送POST请求（JSON格式）
     * @param url 请求URL
     * @param body JSON对象
     * @return 响应对象
     */
    public static func post(url: String, body: JsonObject): LinderHttpResponse {
        LinderHttp(url: RequestUrl.from(url), method: RequestMethod.POST)
            .setBody(body)
            .send()
    }
    
    /**
     * 发送POST请求（表单格式）
     * @param url 请求URL
     * @param body 表单数据
     * @return 响应对象
     */
    public static func post(url: String, body: Form): LinderHttpResponse {
        LinderHttp(url: RequestUrl.from(url), method: RequestMethod.POST)
            .setBody(body)
            .send()
    }
    
    /**
     * 发送PUT请求
     * @param url 请求URL
     * @param body 请求体
     * @return 响应对象
     */
    public static func put(url: String, body: String): LinderHttpResponse {
        LinderHttp(url: RequestUrl.from(url), method: RequestMethod.PUT)
            .setBody(body)
            .send()
    }
    
    /**
     * 发送PUT请求（JSON格式）
     * @param url 请求URL
     * @param body JSON对象
     * @return 响应对象
     */
    public static func put(url: String, body: JsonObject): LinderHttpResponse {
        LinderHttp(url: RequestUrl.from(url), method: RequestMethod.PUT)
            .setBody(body)
            .send()
    }
    
    /**
     * 发送DELETE请求
     * @param url 请求URL
     * @return 响应对象
     */
    public static func delete(url: String): LinderHttpResponse {
        LinderHttp(url: RequestUrl.from(url), method: RequestMethod.DELETE).send()
    }
    
    /**
     * 发送DELETE请求
     * @param url URL对象
     * @return 响应对象
     */
    public static func delete(url: URL): LinderHttpResponse {
        LinderHttp(url: RequestUrl.from(url), method: RequestMethod.DELETE).send()
    }
    
    /**
     * 发送HEAD请求
     * @param url 请求URL
     * @return 响应对象
     */
    public static func head(url: String): LinderHttpResponse {
        LinderHttp(url: RequestUrl.from(url), method: RequestMethod.HEAD).send()
    }
    
    /**
     * 发送OPTIONS请求
     * @param url 请求URL
     * @return 响应对象
     */
    public static func options(url: String): LinderHttpResponse {
        LinderHttp(url: RequestUrl.from(url), method: RequestMethod.OPTION).send()
    }
    
    /**
     * 发送PATCH请求
     * @param url 请求URL
     * @param body 请求体
     * @return 响应对象
     */
    public static func patch(url: String, body: String): LinderHttpResponse {
        LinderHttp(url: RequestUrl.from(url), method: RequestMethod.PATCH)
            .setBody(body)
            .send()
    }
    
    /**
     * 发送PATCH请求（JSON格式）
     * @param url 请求URL
     * @param body JSON对象
     * @return 响应对象
     */
    public static func patch(url: String, body: JsonObject): LinderHttpResponse {
        LinderHttp(url: RequestUrl.from(url), method: RequestMethod.PATCH)
            .setBody(body)
            .send()
    }
}

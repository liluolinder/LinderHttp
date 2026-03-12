package linderHttp

import stdx.net.http.*
import stdx.encoding.url.*
import std.collection.*
import std.time.*

/**
 * LinderCookieJar - Cookie管理器封装
 * 提供简化的Cookie存储和管理功能
 */
public class LinderCookieJar {
    /**
     * 底层CookieJar实例
     */
    private var cookieJar: CookieJar
    
    /**
     * 是否为HTTP协议
     */
    public var isHttp: Bool = true
    
    /**
     * 公共后缀黑名单
     */
    public var rejectPublicSuffixes: ArrayList<String> = ArrayList<String>()
    
    /**
     * 默认构造函数
     */
    public init() {
        this.cookieJar = CookieJar.createDefaultCookieJar(ArrayList<String>(), true)
    }
    
    /**
     * 构造函数
     * @param rejectPublicSuffixes 公共后缀黑名单
     * @param isHttp 是否为HTTP协议
     */
    public init(rejectPublicSuffixes: ArrayList<String>, isHttp!: Bool = true) {
        this.rejectPublicSuffixes = rejectPublicSuffixes
        this.isHttp = isHttp
        this.cookieJar = CookieJar.createDefaultCookieJar(rejectPublicSuffixes, isHttp)
    }
    
    /**
     * 获取底层CookieJar
     * @return CookieJar实例
     */
    public func getRawCookieJar(): CookieJar {
        cookieJar
    }
    
    /**
     * 存储Cookie
     * @param url 产生Cookie的URL
     * @param cookies Cookie列表
     */
    public func storeCookies(url: URL, cookies: ArrayList<Cookie>): Unit {
        cookieJar.storeCookies(url, cookies)
    }
    
    /**
     * 存储单个Cookie
     * @param url 产生Cookie的URL
     * @param cookie Cookie对象
     */
    public func storeCookie(url: URL, cookie: Cookie): Unit {
        let cookies = ArrayList<Cookie>([cookie])
        cookieJar.storeCookies(url, cookies)
    }
    
    /**
     * 获取指定URL的Cookie
     * @param url 目标URL
     * @return Cookie列表
     */
    public func getCookies(url: URL): ArrayList<Cookie> {
        cookieJar.getCookies(url)
    }
    
    /**
     * 获取指定URL的Cookie字符串
     * @param url 目标URL
     * @return Cookie字符串（用于请求头）
     */
    public func getCookieString(url: URL): String {
        let cookies = getCookies(url)
        CookieJar.toCookieString(cookies)
    }
    
    /**
     * 移除指定域名的Cookie
     * @param domain 域名
     */
    public func removeCookies(domain: String): Unit {
        cookieJar.removeCookies(domain)
    }
    
    /**
     * 清除所有Cookie
     */
    public func clear(): Unit {
        cookieJar.clear()
    }
    
    /**
     * 从响应中解析并存储Cookie
     * @param url 请求URL
     * @param response HTTP响应
     */
    public func parseAndStore(url: URL, response: HttpResponse): Unit {
        let cookies = CookieJar.parseSetCookieHeader(response)
        if (!cookies.isEmpty()) {
            storeCookies(url, cookies)
        }
    }
    
    /**
     * 从响应中解析并存储Cookie
     * @param url 请求URL字符串
     * @param response HTTP响应
     */
    public func parseAndStore(url: String, response: HttpResponse): Unit {
        parseAndStore(URL.parse(url), response)
    }
    
    /**
     * 创建简单的Cookie
     * @param name Cookie名称
     * @param value Cookie值
     * @return Cookie对象
     */
    public static func createCookie(name: String, value: String): Cookie {
        Cookie(name, value)
    }
    
    /**
     * 创建带属性的Cookie
     * @param name Cookie名称
     * @param value Cookie值
     * @param domain 域名
     * @param path 路径
     * @param maxAge 最大存活时间（秒）
     * @return Cookie对象
     */
    public static func createCookie(
        name: String, 
        value: String, 
        domain!: String = "", 
        path!: String = "", 
        maxAge!: ?Int64 = None
    ): Cookie {
        Cookie(name, value, maxAge: maxAge, domain: domain, path: path)
    }
    
    /**
     * 创建带过期时间的Cookie
     * @param name Cookie名称
     * @param value Cookie值
     * @param expires 过期时间
     * @param domain 域名
     * @param path 路径
     * @return Cookie对象
     */
    public static func createCookie(
        name: String, 
        value: String, 
        expires: DateTime,
        domain!: String = "", 
        path!: String = ""
    ): Cookie {
        Cookie(name, value, expires: expires, domain: domain, path: path)
    }
    
    /**
     * 创建安全的Cookie
     * @param name Cookie名称
     * @param value Cookie值
     * @param domain 域名
     * @param path 路径
     * @param httpOnly 是否仅HTTP
     * @param secure 是否安全连接
     * @return Cookie对象
     */
    public static func createSecureCookie(
        name: String, 
        value: String, 
        domain!: String = "", 
        path!: String = "",
        httpOnly!: Bool = true,
        secure!: Bool = true
    ): Cookie {
        Cookie(name, value, domain: domain, path: path, secure: secure, httpOnly: httpOnly)
    }
}

package linderHttp

import std.collection.*
import stdx.encoding.url.*
import std.net.*

/**
 * LinderHttp高级功能类
 * 包含CONNECT隧道、协议升级等功能
 */
public class LinderHttpAdvanced {
    /**
     * 底层LinderHttp实例
     */
    private var http: LinderHttp
    
    /**
     * 构造函数
     * @param http LinderHttp实例
     */
    public init(http: LinderHttp) {
        this.http = http
    }
    
    /**
     * 发送CONNECT请求建立隧道
     * 用于通过HTTP代理建立TCP隧道
     * @param url 代理服务器地址
     * @return (响应, 底层Socket)元组，成功时Socket可用于后续通信
     */
    public func connect(url: String): (LinderHttpResponse, ?StreamingSocket) {
        let clientBuilder = ClientBuilder()
            .tlsConfig(http.tlsConfig)
            .autoRedirect(false)
            .readTimeout(http.readTimeout)
            .writeTimeout(http.writeTimeout)
        
        if (http.httpProxy != '') {
            clientBuilder.httpProxy(http.httpProxy)
        }
        if (http.httpsProxy != '') {
            clientBuilder.httpsProxy(http.httpsProxy)
        }
        
        let client = clientBuilder.build()
        let (resp, socket) = client.connect(url, header: http.httpHeader.httpHeader)
        
        let response = LinderHttpResponse(
            body: resp.body,
            bodySize: resp.bodySize,
            status: resp.status,
            headers: resp.headers,
            isPersistent: resp.isPersistent,
            request: resp.request
        )
        (response, socket)
    }
    
    /**
     * 发送协议升级请求
     * 用于将HTTP连接升级到其他协议
     * @param upgradeProtocol 要升级到的协议名称
     * @return (响应, 底层Socket)元组，成功时Socket可用于新协议通信
     */
    public func upgrade(upgradeProtocol: String): (LinderHttpResponse, ?StreamingSocket) {
        http.httpHeader.set(key: "Upgrade", value: upgradeProtocol)
        http.httpHeader.set(key: "Connection", value: "Upgrade")
        
        let clientBuilder = ClientBuilder()
            .tlsConfig(http.tlsConfig)
            .autoRedirect(false)
            .readTimeout(http.readTimeout)
            .writeTimeout(http.writeTimeout)
        
        let client = clientBuilder.build()
        let request = HttpRequestBuilder()
            .method(http.method)
            .url(match (http.url) {
                case RequestUrl.URL(v) => v
                case RequestUrl.STRING(v) => URL.parse(v)
            })
            .setHeaders(http.httpHeader.httpHeader)
            .build()
        
        let (resp, socket) = client.upgrade(request)
        
        let response = LinderHttpResponse(
            body: resp.body,
            bodySize: resp.bodySize,
            status: resp.status,
            headers: resp.headers,
            isPersistent: resp.isPersistent,
            request: resp.request
        )
        (response, socket)
    }
    
    /**
     * 获取HTTP/2服务器推送的响应
     * @param response HTTP响应
     * @return 推送的响应列表，None表示未启用推送功能
     */
    public static func getPushResponses(response: HttpResponse): ?ArrayList<HttpResponse> {
        response.getPush()
    }
}

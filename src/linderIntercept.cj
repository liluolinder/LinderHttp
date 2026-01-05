package linderHttp

public interface LinderIntercept {
    /**
     * 请求发送前拦截函数
     * 触发时机：HTTP请求参数组装完成，即将发起网络请求前
     * @param http LinderHttp 当前HTTP请求对象实例
     *
     */
    func request(http: LinderHttp): Unit

    /**
     * 请求前阶段异常拦截函数
     * 触发时机：请求构建中抛出异常时
     * @param error Exception 捕获的异常对象实例
     */
    func requestError(error: Exception): Unit

    /**
     * 响应接收后拦截函数
     * 触发时机：成功接收到HTTP响应后
     * @param res LinderHttpResponse HTTP响应对象实例
     */
    func response(res: LinderHttpResponse): Unit

    /**
     * 响应处理异常拦截函数
     *
     * 触发时机：响应体解析过程中抛出异常时
     * @param error Exception 捕获的异常对象实例
     */
    func responseError(error: Exception): Unit
}

public class Intercept <: LinderIntercept {
    public Intercept(
        let requestL!: (LinderHttp) -> Unit = {_ =>},
        let requestErrorL!: (Exception) -> Unit = {_ =>},
        let responseL!: (LinderHttpResponse) -> Unit = {_ =>},
        let responseErrorL!: (Exception) -> Unit = {_ =>}
    ) {}
    public func request(http: LinderHttp): Unit {
        requestL(http)
    }
    public func requestError(error: Exception): Unit {
        requestErrorL(error)
    }
    public func response(res: LinderHttpResponse): Unit {
        responseL(res)
    }
    public func responseError(error: Exception): Unit {
        responseErrorL(error)
    }
}

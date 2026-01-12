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

    /**
     * 输入流读取开始时的回调函数
     *
     * 触发时机：调用 `getBodyFile()` 保存响应体到文件时，在首次读取输入流前触发
     * @param totalSize UInt64 InputStream总Byte数
     */
    func onStartRead(totalSize: Int64): Unit

    /**
     * 输入流读取进度更新的回调函数
     *
     * 触发时机：调用 `getBodyFile(filePath)` 保存响应体到文件时，每次从输入流读取数据后触发
     * @param singleReadSize UInt64 单次读取Byte数
     * @param hasReadSize UInt64 已经读取Byte数
     * @param totalSize UInt64 InputStream总Byte数
     */
    func onReadProgressUpdate(singleReadSize: Int64, hasReadSize: Int64, totalSize: Int64): Unit

    /**
     * 输入流读取完成时的回调函数
     *
     * 触发时机：调用 `getBodyFile(filePath:conflictMethod:)` 保存响应体到文件时，在输入流读取结束后触发
     * @param Path 保存文件的地址
     */
    func onReadEnd(path:?Path): Unit
}

public class Intercept <: LinderIntercept {
    public Intercept(
        let requestL!: (LinderHttp) -> Unit = {_ =>},
        let requestErrorL!: (Exception) -> Unit = {_ =>},
        let responseL!: (LinderHttpResponse) -> Unit = {_ =>},
        let responseErrorL!: (Exception) -> Unit = {_ =>},
        let onStartReadL!: (Int64) -> Unit = {_ =>},
        let onReadProgressUpdateL!: (Int64, Int64, Int64) -> Unit = {_, _, _ =>},
        let onReadEndL!: (path:?Path) -> Unit = {_=>}
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

    public func onStartRead(totalSize: Int64): Unit {
        onStartReadL(totalSize)
    }

    public func onReadProgressUpdate(singleReadSize: Int64, hasReadSize: Int64, totalSize: Int64): Unit {
        onReadProgressUpdateL(singleReadSize, hasReadSize, totalSize)
    }

    public func onReadEnd(path:?Path): Unit {
        onReadEndL(path)
    }
}

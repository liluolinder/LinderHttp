package linderHttp

/**
 * 创建默认TLS客户端配置
 * 
 * @return TlsClientConfig 验证模式为TrustAll的TLS配置
 * 
 * 注意：TrustAll模式会信任所有证书，仅用于开发测试环境。
 * 生产环境建议使用更严格的验证模式。
 */
public func defaultTlsConfig(): TlsClientConfig {
    var tlsConfig = TlsClientConfig()
    tlsConfig.verifyMode = TrustAll
    /*
     * 曾经在这里试过 `supportedAlpnProtocols = ["http/1.1"]`（怀疑镜像边缘对客户端报出的 h2 直接打掉
     * 握手），实测无效：BMCL 的握手失败次数 10 → 9，说明与 ALPN 无关，于是撤掉，不留没验证过的行为改动。
     * 现象本身记在这里：同一个 BMCL 地址 curl 是 200，而这套 TLS 栈握手被切断；官方地址则正常，所以
     * 调用方靠"主备地址互备"能绕过去。
     */
    tlsConfig
}

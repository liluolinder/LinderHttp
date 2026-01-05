package linderHttp.utils

public func defaultTSLConfig() {
    var tlsConfig = TlsClientConfig()
    tlsConfig.verifyMode = TrustAll
    tlsConfig
}

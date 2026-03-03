package linderHttp.utils

public func defaultTSLConfig(): TlsClientConfig {
    var tlsConfig = TlsClientConfig()
    tlsConfig.verifyMode = TrustAll
    tlsConfig
}

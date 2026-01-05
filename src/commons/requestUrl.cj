package linderHttp.commons

public enum RequestUrl {
    | STRING(String)
    | URL(URL)

    public static func from(v: String): RequestUrl {
        RequestUrl.STRING(v)
    }

    public static func from(v: URL): RequestUrl {
        RequestUrl.URL(v)
    }
}

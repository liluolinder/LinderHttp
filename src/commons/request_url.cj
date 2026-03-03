package linderHttp.commons

public enum RequestUrl <: ToString {
    | STRING(String)
    | URL(URL)

    public static func from(v: String): RequestUrl {
        RequestUrl.STRING(v)
    }

    public static func from(v: URL): RequestUrl {
        RequestUrl.URL(v)
    }

    public func toString(): String {
        match (this) {
            case STRING(v) => v
            case URL(v) => v.toString()
        }
    }
}

package linderHttp.commons

public enum RequestBody {
    | String(String)
    | InputStream(InputStream)
    | ByteArray(Array<Byte>)
    | Object(DataModel)
    | Json(JsonObject)
    | UrlEncoded(Form)

    public static func from(v: String): RequestBody {
        RequestBody.String(v)
    }

    public static func from(v: InputStream): RequestBody {
        RequestBody.InputStream(v)
    }

    public static func from(v: Array<Byte>): RequestBody {
        RequestBody.ByteArray(v)
    }

    public static func from(v: Form): RequestBody {
        RequestBody.UrlEncoded(v)
    }
    public static func from(v: DataModel): RequestBody {
        RequestBody.Object(v)
    }
    public static func from(v: JsonObject): RequestBody {
        RequestBody.Json(v)
    }
}

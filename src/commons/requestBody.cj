package linderHttp.commons

public enum RequestBody {
    | STRING(String)
    | INPUT_STREAM(InputStream)
    | BYTE_ARRAY(Array<Byte>)
    | OBJECT(DataModel)
    | JSON(JsonObject)
    | URLENCODED(Form)

    public static func from(v: String): RequestBody {
        RequestBody.STRING(v)
    }

    public static func from(v: InputStream): RequestBody {
        RequestBody.INPUT_STREAM(v)
    }

    public static func from(v: Array<Byte>): RequestBody {
        RequestBody.BYTE_ARRAY(v)
    }

    public static func from(v: Form): RequestBody {
        RequestBody.URLENCODED(v)
    }
    public static func from(v: DataModel): RequestBody {
        RequestBody.OBJECT(v)
    }
    public static func from(v: JsonObject): RequestBody {
        RequestBody.JSON(v)
    }
}

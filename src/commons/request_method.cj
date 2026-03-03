package linderHttp.commons

public enum RequestMethod <: ToString {
    | GET
    | POST
    | HEAD
    | PUT
    | PATCH
    | DELETE
    | COPY
    | OPTION
    | LINK
    | UNLINK
    | PURGE
    | LOCK
    | UNLOCK
    | PROPFIND
    | VIEW
    | CUSTOM(String)

    public func toString(): String {
        match (this) {
            case GET => "GET"
            case POST => "POST"
            case HEAD => "HEAD"
            case PUT => "PUT"
            case PATCH => "PATCH"
            case DELETE => "DELETE"
            case COPY => "COPY"
            case OPTION => "OPTION"
            case LINK => "LINK"
            case UNLINK => "UNLINK"
            case PURGE => "PURGE"
            case LOCK => "LOCK"
            case UNLOCK => "UNLOCK"
            case PROPFIND => "PROPFIND"
            case VIEW => "VIEW"
            case CUSTOM(v) => v
        }
    }
}

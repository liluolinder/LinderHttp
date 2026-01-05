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
    | PUGRE
    | LOCK
    | UNLOCK
    | PROPFIND
    | VIEW
    | CUSTOM(String)

    public func toString() {
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
            case PUGRE => "PUGRE"
            case LOCK => "LOCK"
            case UNLOCK => "UNLOCK"
            case PROPFIND => "PROPFIND"
            case VIEW => "VIEW"
            case CUSTOM(v) => v
        }
    }
}

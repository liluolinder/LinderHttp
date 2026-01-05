package linderHttp.utils

public interface StringExport {
    func export2File(filePath!: Path, conflictMethod!: ConflictMethod): Unit

    func exportJson2File(filePath!: Path, conflictMethod!: ConflictMethod): Unit
}

extend String <: StringExport {
    public func export2File(filePath!: Path, conflictMethod!: ConflictMethod = ConflictMethod.HARMONY) {
        export2File(content: this, filePath: filePath, conflictMethod: conflictMethod)
        return
    }

    public func exportJson2File(filePath!: Path, conflictMethod!: ConflictMethod = ConflictMethod.HARMONY) {
        export2File(content: JsonValue.fromStr(this).toJsonString(), filePath: filePath, conflictMethod: conflictMethod)
        return
    }
}

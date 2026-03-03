package linderHttp.utils

/**
 * 将字符串内容导出到指定路径的文件中。
 *
 * 当目标路径已存在同名文件时，根据冲突解决策略处理：
 * - `HARMONY`（默认）：自动生成新文件名（格式：`原文件名(序号).扩展名`），序号从1开始递增直到不冲突。
 * - `OVER_WRITE`：直接覆盖原文件。
 *
 * @param content     要写入的字符串内容，不可为空。
 * @param filePath    目标文件路径（包含文件名和扩展名），不可为空。
 * @param conflictMethod 文件冲突解决策略，默认为`ConflictMethod.Harmony`。
 */
public func export2File(content!: String, filePath!: Path, conflictMethod!: ConflictMethod = ConflictMethod.Harmony): Unit {
    var _filePath = filePath.normalize()
    var _fileName = filePath.fileName

    match (conflictMethod) {
        case ConflictMethod.Harmony =>
            let dir: Array<FileInfo> = Directory.readFrom(filePath.parent)
            let files = dir.map({value => value.name})
            if (files.contains(_fileName)) {
                let fileInPath = Path(_fileName)
                var counter = 1
                let baseName = fileInPath.fileNameWithoutExtension
                let extension = fileInPath.extensionName
                while (files.contains(_fileName)) {
                    _fileName = "${baseName}(${counter}).${extension}"
                    counter++
                }
                _filePath = filePath.parent.join(Path(_fileName))
            }
        case ConflictMethod.OverWrite => _filePath = _filePath
    }
    let file = File(_filePath, OpenMode.Write)
    file.write(content.toArray())
    file.close()
}

/**
 * 将输入流的内容导出到指定路径的文件中。
 *
 * 当目标路径已存在同名文件时，根据冲突解决策略处理：
 * - `HARMONY`（默认）：自动生成新文件名（格式：`原文件名(序号).扩展名`）。
 * - `OVER_WRITE`：直接覆盖原文件。
 *
 * @param content     输入流对象，不可为空（读取后流位置将移动到末尾）。
 * @param filePath    目标文件路径（包含文件名和扩展名），不可为空。
 * @param conflictMethod 文件冲突解决策略，默认为`ConflictMethod.HARMONY`。
 * @param intercept  读取回调拦截函数。
 */
public func export2File(content!: InputStream, filePath!: Path,
    conflictMethod!: ConflictMethod = ConflictMethod.Harmony, totalSize!: Int64,
    intercept!: ?Export2FileIntercept = None): Unit {
    var _filePath = filePath.normalize()
    var _fileName = filePath.fileName

    match (conflictMethod) {
        case ConflictMethod.Harmony =>
            let dir: Array<FileInfo> = Directory.readFrom(filePath.parent)
            let files = dir.map({value => value.name})
            if (files.contains(_fileName)) {
                let fileInPath = Path(_fileName)
                var counter = 1
                let baseName = fileInPath.fileNameWithoutExtension
                let extension = fileInPath.extensionName
                while (files.contains(_fileName)) {
                    _fileName = "${baseName}(${counter}).${extension}"
                    counter++
                }

                _filePath = filePath.parent.join(Path(_fileName))
            }

        case ConflictMethod.OverWrite => _filePath = _filePath
    }

    if (intercept.isSome()) {
        intercept.getOrThrow().onStartRead(totalSize)
    }

    let file = File(_filePath, OpenMode.Write)
    let bitArray: Array<Byte> = Array<Byte>(4096, repeat: 0)
    var readSize = content.read(bitArray)
    var hasReadSize = readSize
    do {
        if (intercept.isSome()) {
            intercept.getOrThrow().onReadProgressUpdate(readSize, hasReadSize, totalSize)
        }
        file.write(bitArray[0..readSize])
        readSize = content.read(bitArray)
        hasReadSize += readSize
    } while (readSize > 0)

    if (intercept.isSome()) {
        intercept.getOrThrow().onReadEnd(_filePath)
    }

    file.close()
}

public class Export2FileIntercept {
    public Export2FileIntercept(
        public var onStartRead!: (Int64) -> Unit = {_ =>},
        public var onReadProgressUpdate!: (Int64, Int64, Int64) -> Unit = {_, _, _ =>},
        public var onReadEnd!: (?Path) -> Unit = {_=>}
    ) {}
}

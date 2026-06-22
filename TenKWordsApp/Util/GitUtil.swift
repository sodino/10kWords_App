import Foundation

/// Git 操作工具。在 dir_Git10000Words 仓库中执行本地 git 命令。
enum GitUtil {

    // MARK: - git add

    /// 将指定文件路径添加到 git 暂存区。
    /// - Parameter filePath: 相对于仓库根目录的文件路径（绝对路径也可以，Process 会正确处理）。
    static func add(filePath: String) {
        runGit(command: "add", arguments: [filePath])
    }

    // MARK: - git commit

    /// 将当前暂存区内容提交到本地仓库。
    /// - Parameter message: 提交信息。
    static func commit(message: String) {
        runGit(command: "commit", arguments: ["-m", message])
    }

    // MARK: - 底层执行

    private static func runGit(command: String, arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.currentDirectoryURL = URL(fileURLWithPath: AppConstants.dir_Git10000Words)
        process.arguments = [command] + arguments

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("[GitUtil] \(command) Failed to start: \(error.localizedDescription)")
            return
        }

        if process.terminationStatus != 0 {
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let errStr = String(data: errData, encoding: .utf8) ?? ""
            print("[GitUtil] \(command) Failed: \(errStr)")
        } else {
            print("[GitUtil] \(command) Succeeded")
        }
    }
}

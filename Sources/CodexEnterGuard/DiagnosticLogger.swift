import Foundation

final class DiagnosticLogger: @unchecked Sendable {
    static let shared = DiagnosticLogger()

    private let fileURL: URL
    private let queue = DispatchQueue(label: "local.codex-send-guard.diagnostics")

    private init() {
        fileURL = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/CodexSendGuard.log")
    }

    func write(_ message: String) {
        queue.async { [fileURL] in
            let line = "\(ISO8601DateFormatter().string(from: Date())) \(message)\n"
            let data = Data(line.utf8)

            do {
                try FileManager.default.createDirectory(
                    at: fileURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )

                if FileManager.default.fileExists(atPath: fileURL.path) {
                    let handle = try FileHandle(forWritingTo: fileURL)
                    try handle.seekToEnd()
                    try handle.write(contentsOf: data)
                    try handle.close()
                } else {
                    try data.write(to: fileURL)
                }
            } catch {
                NSLog("Codex 防误发无法写入诊断日志：\(error.localizedDescription)")
            }
        }
    }
}

import Foundation

enum DebugLog {
    private static let url = URL(fileURLWithPath: "/tmp/autotranslator.log")
    private static let queue = DispatchQueue(label: "com.matsuokashuhei.AutoTranslator.debuglog")

    static func log(_ message: String) {
        let line = "\(Date()) \(message)\n"
        queue.async {
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                handle.write(Data(line.utf8))
                try? handle.close()
            } else {
                try? line.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}

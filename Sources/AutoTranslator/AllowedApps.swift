import Foundation

enum AllowedApps {
    /// 完全一致で許可する bundle identifier
    static let exact: Set<String> = [
        "com.apple.Safari",     // Safari（Web ページ）
        "com.apple.Preview",    // Preview（PDF ファイル）
        "com.amazon.Lassen"     // Amazon Kindle
    ]

    /// 前方一致で許可する bundle identifier（Safari の Web アプリなど）
    static let prefixes: [String] = [
        "com.apple.Safari.WebApp."
    ]

    static func isAllowed(bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else { return false }
        if exact.contains(bundleIdentifier) { return true }
        return prefixes.contains { bundleIdentifier.hasPrefix($0) }
    }
}

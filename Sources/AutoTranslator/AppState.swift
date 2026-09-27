import Foundation

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isEnabled: Bool = true
    @Published var sourceLanguageIdentifier: String? = "en"   // 常に英語
    @Published var targetLanguageIdentifier: String = "ja"

    private init() {}
}

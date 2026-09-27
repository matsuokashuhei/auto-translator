import SwiftUI

@main
struct AutoTranslatorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = AppState.shared

    var body: some Scene {
        MenuBarExtra("AutoTranslator", systemImage: "character.book.closed.fill") {
            Toggle("選択したら自動で翻訳", isOn: $state.isEnabled)

            Divider()

            Picker("翻訳元の言語", selection: $state.sourceLanguageIdentifier) {
                Text("英語").tag(Optional<String>.some("en"))
                Text("自動判定").tag(Optional<String>.none)
            }

            Divider()

            Text("対象アプリ: Safari / Preview(PDF) / Kindle")

            Divider()

            Button("アクセシビリティ権限を設定…") {
                appDelegate.requestAccessibility()
            }

            Button("AutoTranslator を終了") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

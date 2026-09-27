import SwiftUI
import Translation
import _Translation_SwiftUI

struct TranslationPanelView: View {
    let sourceText: String
    let sourceLanguageIdentifier: String?
    let targetLanguageIdentifier: String
    var onContentChanged: (() -> Void)?
    var onClose: (() -> Void)?

    @State private var translated = ""
    @State private var isTranslating = true
    @State private var errorMessage: String?
    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            Divider()
            content
        }
        .padding(14)
        .frame(width: 360, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12))
        )
        .onChange(of: translated) { onContentChanged?() }
        .onChange(of: isTranslating) { onContentChanged?() }
        .onChange(of: errorMessage) { onContentChanged?() }
        .task(id: sourceText) { startTranslation() }
        .translationTask(configuration) { session in
            await performTranslation(using: session)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(sourceText)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(translated.isEmpty ? sourceText : translated, forType: .string)
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("コピー")

            Button {
                onClose?()
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("閉じる")
        }
    }

    @ViewBuilder
    private var content: some View {
        if isTranslating {
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("翻訳中…")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if let errorMessage {
            Text(errorMessage)
                .font(.system(size: 12))
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(translated)
                .font(.system(size: 15))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func startTranslation() {
        translated = ""
        errorMessage = nil
        isTranslating = true

        let source = sourceLanguageIdentifier.map { Locale.Language(identifier: $0) }
        let target = Locale.Language(identifier: targetLanguageIdentifier)

        if configuration == nil {
            configuration = TranslationSession.Configuration(source: source, target: target)
        } else {
            configuration?.invalidate()
        }
    }

    private func performTranslation(using session: TranslationSession) async {
        do {
            let response = try await session.translate(sourceText)
            await MainActor.run {
                translated = response.targetText
                isTranslating = false
            }
        } catch {
            if isLanguagePackMissing(error) {
                do {
                    try await session.prepareTranslation()
                    let response = try await session.translate(sourceText)
                    await MainActor.run {
                        translated = response.targetText
                        isTranslating = false
                    }
                    return
                } catch {
                    // fall through to the generic error handling below
                }
            }
            await MainActor.run {
                errorMessage = localizedMessage(for: error)
                isTranslating = false
            }
        }
    }

    private func isLanguagePackMissing(_ error: Error) -> Bool {
        if #available(macOS 26.0, *) {
            return TranslationError.notInstalled ~= error
        }
        return false
    }

    private func localizedMessage(for error: Error) -> String {
        if isLanguagePackMissing(error) {
            return "日本語の言語パックが未インストールです。システム設定 > 一般 > 言語と地域 > 翻訳言語 から追加してください。"
        }
        if TranslationError.unsupportedSourceLanguage ~= error {
            return "この言語は翻訳に対応していません。"
        }
        if TranslationError.unableToIdentifyLanguage ~= error {
            return "言語を判定できませんでした。"
        }
        if TranslationError.nothingToTranslate ~= error {
            return "翻訳するテキストがありません。"
        }
        return "翻訳に失敗しました。"
    }
}

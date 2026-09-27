import AppKit

@MainActor
final class SelectionMonitor {

    var onShow: ((String, CGRect?) -> Void)?
    var onHide: (() -> Void)?

    var isEnabled = true
    var sourceLanguage: String?      // nil = 自動判定

    private var timer: Timer?
    private var lastText = ""
    private var lastLoggedText = ""

    func start() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 0.3, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        reset()
    }

    private func reset() {
        guard !lastText.isEmpty else { return }
        lastText = ""
        onHide?()
    }

    private func poll() {
        guard isEnabled else { return }

        // ドラッグ選択の途中（マウスボタン押下中）は無視する
        guard NSEvent.pressedMouseButtons & 1 == 0 else { return }

        guard let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
            return
        }

        // 対象アプリ（Safari / Preview(PDF) / Kindle）のみ翻訳する
        guard AllowedApps.isAllowed(bundleIdentifier: app.bundleIdentifier) else {
            reset()
            return
        }

        let selection = SelectionReader.frontmostSelection()
        let text = selection?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if text != lastLoggedText {
            var extra = ""
            if text.isEmpty {
                extra = SelectionReader.probe(pid: app.processIdentifier)
            }
            DebugLog.log("poll app=\(app.bundleIdentifier ?? app.localizedName ?? "?") selectedLength=\(text.count) eligible=\(SelectionReader.isTranslatable(text)) preview=\(text.prefix(40)) \(extra)")
            lastLoggedText = text
        }

        guard let selection else {
            reset()
            return
        }

        guard SelectionReader.isTranslatable(text) else { return }
        guard text != lastText else { return }

        lastText = text
        onShow?(text, selection.bounds)
    }
}

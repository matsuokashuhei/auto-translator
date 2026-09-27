import AppKit
import ApplicationServices
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private let monitor = SelectionMonitor()
    private let popup = PopupController()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let state = AppState.shared
        monitor.sourceLanguage = state.sourceLanguageIdentifier

        monitor.onShow = { [weak self] text, bounds in
            self?.popup.show(text: text, bounds: bounds)
        }
        monitor.onHide = { [weak self] in
            self?.popup.hide()
        }

        state.$isEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                guard let self else { return }
                self.monitor.isEnabled = enabled
                if !enabled { self.popup.hide() }
            }
            .store(in: &cancellables)

        state.$sourceLanguageIdentifier
            .receive(on: RunLoop.main)
            .sink { [weak self] identifier in
                self?.monitor.sourceLanguage = identifier
            }
            .store(in: &cancellables)

        // 権限が未付与でも監視は開始しておく（付与後にそのまま動作する）
        let trusted = isAccessibilityTrusted(prompt: true)
        DebugLog.log("launch trusted=\(trusted) bundle=\(Bundle.main.bundleIdentifier ?? "?") path=\(Bundle.main.bundlePath)")
        monitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    func requestAccessibility() {
        isAccessibilityTrusted(prompt: true)
    }

    @discardableResult
    private func isAccessibilityTrusted(prompt: Bool) -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}

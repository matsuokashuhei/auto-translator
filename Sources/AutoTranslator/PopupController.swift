import AppKit
import SwiftUI

@MainActor
final class PopupController {

    private var panel: NSPanel?
    private var hostingView: NSHostingView<TranslationPanelView>?
    private var anchorPoint: NSPoint = .zero
    private let panelWidth: CGFloat = 360
    private let gap: CGFloat = 8

    func show(text: String, bounds: CGRect?) {
        let state = AppState.shared
        let panel = panel ?? makePanel()
        self.panel = panel

        // 選択範囲の位置をアンカーに、無ければマウス位置を使う
        if let bounds {
            anchorPoint = cocoaPoint(fromQuartz: CGPoint(x: bounds.minX, y: bounds.maxY))
        } else {
            anchorPoint = NSEvent.mouseLocation
        }

        let view = TranslationPanelView(
            sourceText: text,
            sourceLanguageIdentifier: state.sourceLanguageIdentifier,
            targetLanguageIdentifier: state.targetLanguageIdentifier,
            onContentChanged: { [weak self] in
                self?.updateLayout()
            },
            onClose: { [weak self] in
                self?.hide()
            }
        )

        let hosting = NSHostingView(rootView: view)
        hosting.sizingOptions = [.intrinsicContentSize]
        panel.contentView = hosting
        self.hostingView = hosting

        updateLayout()
        panel.orderFrontRegardless()
        updateLayout()
    }

    func hide() {
        panel?.orderOut(nil)
        hostingView = nil
    }

    // MARK: - Private

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: 120),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        return panel
    }

    private func updateLayout() {
        guard let panel, let hostingView else { return }

        let fitting = hostingView.fittingSize
        let size = NSSize(width: panelWidth, height: max(fitting.height, 56))
        panel.setContentSize(size)

        let screen = NSScreen.screens.first { $0.frame.contains(anchorPoint) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
        let visible = screen?.visibleFrame ?? .zero

        var origin = NSPoint(x: anchorPoint.x, y: anchorPoint.y - size.height - gap)
        if origin.y < visible.minY + gap {
            origin.y = anchorPoint.y + gap
        }
        origin.x = min(max(origin.x, visible.minX + gap), max(visible.maxX - size.width - gap, visible.minX + gap))
        origin.y = min(max(origin.y, visible.minY + gap), max(visible.maxY - size.height - gap, visible.minY + gap))

        panel.setFrameOrigin(origin)
    }

    private func cocoaPoint(fromQuartz point: CGPoint) -> NSPoint {
        guard let primary = NSScreen.screens.first else { return NSPoint(x: point.x, y: point.y) }
        return NSPoint(x: point.x, y: primary.frame.height - point.y)
    }
}

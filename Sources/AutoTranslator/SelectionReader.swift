import AppKit
import ApplicationServices

struct Selection {
    let text: String
    let bounds: CGRect?
}

enum SelectionReader {

    static func frontmostSelection() -> Selection? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        return selection(forPID: app.processIdentifier)
    }

    static func selection(forPID pid: pid_t) -> Selection? {
        let appElement = AXUIElementCreateApplication(pid)
        guard let focused = copyElement(appElement, kAXFocusedUIElementAttribute) else {
            return nil
        }
        // まず AXSelectedText を試し、未対応のアプリでは選択範囲の文字列取得にフォールバックする
        let selected = copyString(focused, kAXSelectedTextAttribute)
            ?? stringForSelectedRange(focused)
        guard let text = selected, !text.isEmpty else {
            return nil
        }
        return Selection(text: text, bounds: selectionBounds(focused))
    }

    static func probe(pid: pid_t) -> String {
        let appElement = AXUIElementCreateApplication(pid)
        var focusedValue: CFTypeRef?
        let focusError = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedValue)
        guard focusError == .success, let focusedValue,
              CFGetTypeID(focusedValue) == AXUIElementGetTypeID() else {
            return "focusErr=\(focusError.rawValue)"
        }
        let focused = focusedValue as! AXUIElement
        var selectedValue: CFTypeRef?
        let selectedError = AXUIElementCopyAttributeValue(focused, kAXSelectedTextAttribute as CFString, &selectedValue)
        var rangeValue: CFTypeRef?
        let rangeError = AXUIElementCopyAttributeValue(focused, kAXSelectedTextRangeAttribute as CFString, &rangeValue)
        var role: CFTypeRef?
        _ = AXUIElementCopyAttributeValue(focused, kAXRoleAttribute as CFString, &role)
        return "focusErr=\(focusError.rawValue) selectedTextErr=\(selectedError.rawValue) selectedRangeErr=\(rangeError.rawValue) role=\(role ?? "?" as CFString)"
    }

    static func isTranslatable(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 5_000 else { return false }
        guard trimmed.range(of: "[A-Za-z]", options: .regularExpression) != nil else {
            return false
        }
        let japanese = "[\\p{Hiragana}\\p{Katakana}\\p{Han}]"
        guard trimmed.range(of: japanese, options: .regularExpression) == nil else {
            return false
        }
        return true
    }

    // MARK: - Accessibility helpers

    private static func copyAttribute(_ element: AXUIElement, _ attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
            return nil
        }
        return value
    }

    private static func copyElement(_ element: AXUIElement, _ attribute: String) -> AXUIElement? {
        guard let value = copyAttribute(element, attribute),
              CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }
        return (value as! AXUIElement)
    }

    private static func copyString(_ element: AXUIElement, _ attribute: String) -> String? {
        copyAttribute(element, attribute) as? String
    }

    private static func stringForSelectedRange(_ element: AXUIElement) -> String? {
        guard let rangeValue = copyAttribute(element, kAXSelectedTextRangeAttribute),
              CFGetTypeID(rangeValue) == AXValueGetTypeID() else {
            return nil
        }
        var result: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXStringForRangeParameterizedAttribute as CFString,
            rangeValue,
            &result
        ) == .success else {
            return nil
        }
        return result as? String
    }

    private static func selectionBounds(_ element: AXUIElement) -> CGRect? {
        guard let rangeValue = copyAttribute(element, kAXSelectedTextRangeAttribute),
              CFGetTypeID(rangeValue) == AXValueGetTypeID() else {
            return nil
        }
        var range = CFRange()
        guard AXValueGetValue(rangeValue as! AXValue, .cfRange, &range) else { return nil }

        var result: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            rangeValue,
            &result
        ) == .success, let boundsValue = result,
            CFGetTypeID(boundsValue) == AXValueGetTypeID() else {
            return nil
        }

        var rect = CGRect.zero
        guard AXValueGetValue(boundsValue as! AXValue, .cgRect, &rect), !rect.isEmpty else {
            return nil
        }
        return rect
    }
}

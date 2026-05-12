import AppKit
import SwiftUI

struct PlainTaskTextField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let textColor: Color
    let isStruckThrough: Bool
    let onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit)
    }

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.delegate = context.coordinator
        field.isBordered = false
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.usesSingleLineMode = true
        field.lineBreakMode = .byTruncatingTail
        field.placeholderString = placeholder
        field.font = Self.taskFont
        field.cell?.wraps = false
        field.cell?.isScrollable = true
        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        let font = Self.taskFont
        let baseTextColor = NSColor(textColor)
        let resolvedTextColor = baseTextColor.withAlphaComponent(isStruckThrough ? 0.50 : 0.94)
        let isEditing = field.currentEditor() != nil
        let shouldRenderAttributedText = isStruckThrough && !isEditing
        let didStyleChange = context.coordinator.renderedIsStruckThrough != isStruckThrough
            || !Self.colorsEqual(context.coordinator.renderedBaseTextColor, baseTextColor)
        let needsAttributedRefresh = shouldRenderAttributedText
            && (context.coordinator.renderedAttributedText != text || didStyleChange)

        context.coordinator.onSubmit = onSubmit

        if field.font != font {
            field.font = font
        }
        if field.textColor != resolvedTextColor {
            field.textColor = resolvedTextColor
        }
        Self.updatePlaceholderIfNeeded(
            field,
            placeholder: placeholder,
            textColor: baseTextColor,
            font: font,
            coordinator: context.coordinator
        )

        guard field.stringValue != text || didStyleChange || needsAttributedRefresh else {
            return
        }

        context.coordinator.renderedIsStruckThrough = isStruckThrough
        context.coordinator.renderedBaseTextColor = baseTextColor

        if !shouldRenderAttributedText {
            context.coordinator.renderedAttributedText = nil
            field.stringValue = text
            return
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: resolvedTextColor,
            .paragraphStyle: Self.truncatingParagraphStyle,
            .strikethroughStyle: NSUnderlineStyle.single.rawValue,
            .strikethroughColor: baseTextColor.withAlphaComponent(0.46)
        ]

        field.attributedStringValue = NSAttributedString(string: text, attributes: attributes)
        context.coordinator.renderedAttributedText = text
    }

    private static let taskFont: NSFont =
        NSFont(name: "Helvetica Neue", size: StickyMetrics.taskFontSize)
            ?? NSFont.systemFont(ofSize: StickyMetrics.taskFontSize, weight: .regular)

    private static let truncatingParagraphStyle: NSParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byTruncatingTail
        return style
    }()

    private static func updatePlaceholderIfNeeded(
        _ field: NSTextField,
        placeholder: String,
        textColor: NSColor,
        font: NSFont,
        coordinator: Coordinator
    ) {
        guard coordinator.renderedPlaceholder != placeholder
            || !colorsEqual(coordinator.renderedPlaceholderTextColor, textColor) else {
            return
        }

        field.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: textColor.withAlphaComponent(placeholder.isEmpty ? 0.0 : 0.34),
                .font: font
            ]
        )
        coordinator.renderedPlaceholder = placeholder
        coordinator.renderedPlaceholderTextColor = textColor
    }

    private static func colorsEqual(_ lhs: NSColor?, _ rhs: NSColor) -> Bool {
        lhs?.isEqual(rhs) == true
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding private var text: String
        var onSubmit: () -> Void
        var renderedPlaceholder: String?
        var renderedPlaceholderTextColor: NSColor?
        var renderedBaseTextColor: NSColor?
        var renderedAttributedText: String?
        var renderedIsStruckThrough = false

        init(text: Binding<String>, onSubmit: @escaping () -> Void) {
            self._text = text
            self.onSubmit = onSubmit
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            text = field.stringValue
        }

        func control(
            _ control: NSControl,
            textView: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            guard commandSelector == #selector(NSResponder.insertNewline(_:)) else {
                return false
            }

            if let field = control as? NSTextField {
                text = field.stringValue
            }
            onSubmit()
            return true
        }
    }
}

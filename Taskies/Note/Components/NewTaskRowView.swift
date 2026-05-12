import SwiftUI

struct NewTaskRowView: View {
    @Binding var text: String
    let textColor: Color
    let accentColor: Color
    let onSubmit: () -> Void

    @State private var isHovered = false

    private var hasText: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(alignment: .center, spacing: StickyMetrics.rowGlyphSpacing) {
            Image(systemName: "plus")
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(textColor.opacity(isHovered || hasText ? 0.5 : 0.3))
                .frame(width: StickyMetrics.rowGlyphSize, height: StickyMetrics.rowGlyphSize)

            PlainTaskTextField(
                text: $text,
                placeholder: "New task",
                textColor: textColor,
                isStruckThrough: false,
                onSubmit: submitIfNeeded
            )
            .frame(height: StickyMetrics.rowGlyphSize)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, StickyMetrics.rowHPadding)
        .padding(.vertical, StickyMetrics.rowVPadding)
        .frame(minHeight: StickyMetrics.rowMinHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(textColor.opacity(isHovered && !hasText ? 0.04 : 0))
                .padding(.horizontal, StickyMetrics.rowHighlightInset)
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: isHovered)
    }

    private func submitIfNeeded() {
        guard hasText else { return }
        onSubmit()
    }
}

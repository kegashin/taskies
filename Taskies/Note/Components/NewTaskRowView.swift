import SwiftUI

struct NewTaskRowView: View {
    @Binding var text: String
    let textColor: Color
    let accentColor: Color
    let onSubmit: () -> Void

    @State private var isHovered = false

    var body: some View {
        PlainTaskTextField(
            text: $text,
            placeholder: "",
            textColor: textColor,
            isStruckThrough: false,
            onSubmit: submitIfNeeded
        )
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: StickyMetrics.rowMinHeight)
            .padding(.horizontal, StickyMetrics.rowHPadding)
            .padding(.vertical, 1.5)
            .background {
                Rectangle()
                    .fill(textColor.opacity(isHovered && text.isEmpty ? 0.026 : 0))
            }
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
            .animation(.easeInOut(duration: 0.11), value: isHovered)
    }

    private func submitIfNeeded() {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        onSubmit()
    }
}

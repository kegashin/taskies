import SwiftUI

struct TaskRowView: View {
    let item: NoteItem
    let textColor: Color
    let accentColor: Color
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onTextChange: (String) -> Void

    @State private var isHovered = false

    private var textBinding: Binding<String> {
        Binding(
            get: { item.text },
            set: { onTextChange($0) }
        )
    }

    private var isDone: Bool {
        item.status == .done
    }

    var body: some View {
        HStack(alignment: .center, spacing: StickyMetrics.rowGlyphSpacing) {
            checkbox

            PlainTaskTextField(
                text: textBinding,
                placeholder: "",
                textColor: textColor,
                isStruckThrough: isDone,
                onSubmit: {}
            )
            .frame(height: StickyMetrics.rowGlyphSize)
            .frame(maxWidth: .infinity, alignment: .leading)

            deleteButton
        }
        .padding(.horizontal, StickyMetrics.rowHPadding)
        .padding(.vertical, StickyMetrics.rowVPadding)
        .frame(minHeight: StickyMetrics.rowMinHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowHighlight)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .contextMenu {
            Button(isDone ? "Mark as To Do" : "Mark as Done") {
                onToggle()
            }

            Divider()

            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }

    private var rowHighlight: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(textColor.opacity(isHovered ? 0.055 : 0))
            .padding(.horizontal, StickyMetrics.rowHighlightInset)
    }

    private var checkbox: some View {
        Button(action: onToggle) {
            ZStack {
                Circle()
                    .fill(isDone ? accentColor.opacity(0.16) : Color.clear)

                Circle()
                    .strokeBorder(
                        isDone
                            ? accentColor.opacity(0.55)
                            : textColor.opacity(isHovered ? 0.50 : 0.32),
                        lineWidth: 1.3
                    )

                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(accentColor.opacity(0.92))
                }
            }
            .frame(width: StickyMetrics.checkboxSize, height: StickyMetrics.checkboxSize)
            .frame(width: StickyMetrics.rowGlyphSize, height: StickyMetrics.rowGlyphSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(isDone ? "Mark as To Do" : "Mark as Done")
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "xmark")
                .font(.system(size: 7.5, weight: .semibold))
                .foregroundStyle(textColor.opacity(isHovered ? 0.4 : 0))
                .frame(width: StickyMetrics.rowGlyphSize, height: StickyMetrics.rowGlyphSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Delete Task")
        .allowsHitTesting(isHovered)
    }
}

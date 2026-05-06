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
        HStack(alignment: .center, spacing: 8) {
            Button(action: onToggle) {
                ZStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 17, height: 17)

                    Rectangle()
                        .fill(isDone ? accentColor.opacity(0.09) : Color.clear)
                        .frame(width: 10, height: 10)
                        .overlay {
                            Rectangle()
                                .stroke(
                                    isDone ? accentColor.opacity(0.68) : textColor.opacity(isHovered ? 0.54 : 0.42),
                                    lineWidth: 0.95
                                )
                        }
                        .overlay {
                            if isDone {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 7.3, weight: .bold))
                                    .foregroundStyle(accentColor.opacity(0.82))
                            }
                        }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(isDone ? "Mark as To Do" : "Mark as Done")

            PlainTaskTextField(
                text: textBinding,
                placeholder: "",
                textColor: textColor,
                isStruckThrough: isDone,
                onSubmit: {}
            )
                .frame(height: 19)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 6.8, weight: .bold))
                    .foregroundStyle(textColor.opacity(isHovered ? 0.42 : 0))
                    .frame(width: 16, height: 16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Delete Task")
            .allowsHitTesting(isHovered)
        }
        .padding(.horizontal, StickyMetrics.rowHPadding)
        .padding(.vertical, 1.5)
        .frame(minHeight: StickyMetrics.rowMinHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Rectangle()
                .fill(textColor.opacity(isHovered ? 0.035 : 0))
        }
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.11), value: isHovered)
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
}

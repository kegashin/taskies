import SwiftUI

struct DoneSectionView: View {
    let items: [NoteItem]
    @Binding var isExpanded: Bool
    let textColor: Color
    let accentColor: Color
    let onToggle: (NoteItem) -> Void
    let onDelete: (NoteItem) -> Void
    let onTextChange: (NoteItem, String) -> Void
    let onClearAll: () -> Void

    @State private var isHeaderHovered = false

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(textColor.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, StickyMetrics.rowHPadding)
                .padding(.top, 7)

            HStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: StickyMetrics.rowGlyphSpacing) {
                        DoneDisclosureMark(isExpanded: isExpanded)
                            .stroke(
                                textColor.opacity(isHeaderHovered ? 0.58 : 0.42),
                                style: StrokeStyle(lineWidth: 1.15, lineCap: .round, lineJoin: .round)
                            )
                            .frame(width: 7, height: 7)
                            .frame(width: StickyMetrics.rowGlyphSize, height: 14)

                        HStack(spacing: 5) {
                            Text("Done")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(textColor.opacity(isHeaderHovered || isExpanded ? 0.58 : 0.46))

                            Text("\(items.count)")
                                .font(.system(size: 9, weight: .regular))
                                .monospacedDigit()
                                .foregroundStyle(textColor.opacity(isHeaderHovered ? 0.42 : 0.32))
                        }

                        Spacer(minLength: 4)
                    }
                    .frame(maxWidth: .infinity, minHeight: 18, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Button {
                        onClearAll()
                    } label: {
                        Image(systemName: "archivebox")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(accentColor.opacity(0.66))
                            .frame(width: 16, height: 16)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Archive Done...")
                    .opacity(isHeaderHovered ? 1 : 0)
                    .allowsHitTesting(isHeaderHovered)
                }
            }
            .padding(.leading, StickyMetrics.rowHPadding)
            .padding(.trailing, max(0, StickyMetrics.rowHPadding - 3))
            .padding(.top, 3)
            .padding(.bottom, 2)
            .contentShape(Rectangle())
            .onHover { isHeaderHovered = $0 }
            .animation(.easeInOut(duration: 0.12), value: isHeaderHovered)
            .contextMenu {
                Button(isExpanded ? "Collapse Done" : "Expand Done") {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        isExpanded.toggle()
                    }
                }

                if isExpanded {
                    Divider()

                    Button("Archive Done...", role: .destructive) {
                        onClearAll()
                    }
                }
            }

            if isExpanded {
                ForEach(items) { item in
                    TaskRowView(
                        item: item,
                        textColor: textColor,
                        accentColor: accentColor,
                        onToggle: { onToggle(item) },
                        onDelete: { onDelete(item) },
                        onTextChange: { newText in
                            onTextChange(item, newText)
                        }
                    )
                }
            }
        }
    }
}

private struct DoneDisclosureMark: Shape {
    let isExpanded: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()

        if isExpanded {
            path.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.34))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.66))
            path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.minY + rect.height * 0.34))
        } else {
            path.move(to: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.minY + rect.height * 0.18))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.66, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.maxY - rect.height * 0.18))
        }

        return path
    }
}

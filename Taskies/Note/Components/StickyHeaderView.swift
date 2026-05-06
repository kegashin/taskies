import AppKit
import SwiftData
import SwiftUI

struct StickyHeaderView: View {
    @Bindable var viewModel: StickyNoteViewModel
    @State private var isHoveringTriangle = false

    private var color: StickyColor {
        viewModel.stickyNote.color
    }

    private var isActive: Bool {
        viewModel.windowCoordinator.activeNoteId == viewModel.stickyNote.id
    }

    private var controlStrokeColor: Color {
        color.palette.border.opacity(0.52)
    }

    private var controlHoverStrokeColor: Color {
        color.palette.border.opacity(0.64)
    }

    var body: some View {
        HStack(spacing: 4) {
            deleteBox
                .opacity(isActive ? 1 : 0)
                .disabled(!isActive)
                .allowsHitTesting(isActive)

            titleDragArea

            triangleButton
                .opacity(isActive ? 1 : 0)
                .disabled(!isActive)
                .allowsHitTesting(isActive)
            collapseBox
                .opacity(isActive ? 1 : 0)
                .disabled(!isActive)
                .allowsHitTesting(isActive)
        }
        .padding(.leading, 12)
        .padding(.trailing, 12)
        .frame(height: StickyMetrics.headerHeight)
        .background(StickyTitleBarBackground(color: color, isActive: isActive))
        .contentShape(Rectangle())
        .alert("Delete Note?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.confirmDelete()
            }
        } message: {
            Text("Delete \"\(viewModel.displayTitle)\" and all tasks?")
        }
    }

    private var titleDragArea: some View {
        ZStack(alignment: .leading) {
            WindowDragHandle {
                viewModel.toggleCollapse()
            }

            if viewModel.isCollapsed {
                Button {
                    viewModel.rename()
                } label: {
                    Text(viewModel.displayTitle)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(color.textColor)
                        .lineLimit(1)
                        .padding(.horizontal, 2)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Rename Note")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var deleteBox: some View {
        Button {
            viewModel.requestDelete()
        } label: {
            Rectangle()
                .fill(color.palette.paperTop)
                .frame(width: 8, height: 8)
                .overlay {
                    Rectangle()
                        .stroke(controlStrokeColor, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .help("Delete Note")
    }

    private var triangleButton: some View {
        Button {
            viewModel.zoom()
        } label: {
            StickyTriangle()
                .fill(color.palette.paperTop)
                .overlay {
                    StickyTriangle()
                        .stroke(
                            isHoveringTriangle ? controlHoverStrokeColor : controlStrokeColor,
                            style: StrokeStyle(lineWidth: 1, lineJoin: .miter)
                        )
                }
                .frame(width: 8.5, height: 8.5)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Zoom")
        .onHover { isHoveringTriangle = $0 }
    }

    private var collapseBox: some View {
        Button {
            viewModel.toggleCollapse()
        } label: {
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(color.palette.paperTop)
                    .overlay {
                        Rectangle()
                            .stroke(controlStrokeColor, lineWidth: 1)
                    }

                Rectangle()
                    .fill(controlStrokeColor)
                    .frame(height: 1)
                    .padding(.horizontal, 1)
                    .padding(.top, 2.5)
            }
            .frame(width: 8, height: 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(viewModel.isCollapsed ? "Expand" : "Collapse")
    }
}

private struct WindowDragHandle: NSViewRepresentable {
    let onDoubleClick: () -> Void

    func makeNSView(context: Context) -> DragView {
        let view = DragView()
        view.onDoubleClick = onDoubleClick
        return view
    }

    func updateNSView(_ nsView: DragView, context: Context) {
        nsView.onDoubleClick = onDoubleClick
    }

    final class DragView: NSView {
        var onDoubleClick: () -> Void = {}

        override func mouseDown(with event: NSEvent) {
            if event.clickCount == 2 {
                onDoubleClick()
                return
            }

            window?.performDrag(with: event)
        }
    }
}

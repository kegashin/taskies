import SwiftData
import SwiftUI

struct StickyNoteView: View {
    @Bindable var viewModel: StickyNoteViewModel

    private var color: StickyColor {
        viewModel.stickyNote.color
    }

    var body: some View {
        noteContent(
            todoItems: viewModel.isCollapsed ? [] : viewModel.todoItems,
            doneItems: viewModel.isCollapsed ? [] : viewModel.doneItems
        )
    }

    private func noteContent(todoItems: [NoteItem], doneItems: [NoteItem]) -> some View {
        ZStack {
            StickyPaperBackground(color: color)

            VStack(spacing: 0) {
                StickyHeaderView(viewModel: viewModel)

                if !viewModel.isCollapsed {
                    ZStack(alignment: .topLeading) {
                        StickyNoteBodyBackground(color: color)

                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 1) {
                                ForEach(todoItems) { item in
                                    TaskRowView(
                                        item: item,
                                        textColor: color.textColor,
                                        accentColor: color.accentColor,
                                        onToggle: { viewModel.toggleDone(item) },
                                        onDelete: { viewModel.deleteTask(item) },
                                        onTextChange: { newText in
                                            viewModel.updateTaskText(item, newText: newText)
                                        }
                                    )
                                }
                                .onMove { source, destination in
                                    viewModel.moveTask(from: source, to: destination)
                                }

                                NewTaskRowView(
                                    text: $viewModel.newTaskText,
                                    textColor: color.textColor,
                                    accentColor: color.accentColor,
                                    onSubmit: {
                                        viewModel.addTask(text: viewModel.newTaskText)
                                    }
                                )

                                if !doneItems.isEmpty {
                                    DoneSectionView(
                                        items: doneItems,
                                        isExpanded: $viewModel.isDoneSectionExpanded,
                                        textColor: color.textColor,
                                        accentColor: color.accentColor,
                                        onToggle: { item in viewModel.toggleDone(item) },
                                        onDelete: { item in viewModel.deleteTask(item) },
                                        onTextChange: { item, newText in
                                            viewModel.updateTaskText(item, newText: newText)
                                        },
                                        onClearAll: { viewModel.clearDone() }
                                    )
                                }
                            }
                            .padding(.top, 6)
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                        .scrollIndicators(.hidden)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .overlay {
            Rectangle()
                .stroke(Color.black.opacity(0.82), lineWidth: 1)
        }
        .alert("Archive Done?", isPresented: $viewModel.showArchiveDoneConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Archive", role: .destructive) {
                viewModel.confirmArchiveDone()
            }
        } message: {
            Text("Archive completed tasks? They will be hidden from this note.")
        }
    }
}

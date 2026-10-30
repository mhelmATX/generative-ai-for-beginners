import SwiftUI
import SwiftData

struct ColumnView: View {
    let column: BoardColumn
    let tasks: [TaskItem]
    let isFirst: Bool
    let isLast: Bool
    let canDelete: Bool
    var onSelect: (TaskItem) -> Void
    var onRename: () -> Void
    var onMove: (Int) -> Void
    var onDelete: () -> Void

    @Environment(\.modelContext) private var context
    @State private var draft = ""
    @State private var isTargeted = false
    @FocusState private var quickAddFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(tasks) { task in
                        TaskCard(task: task)
                            .contentShape(Rectangle())
                            .onTapGesture { onSelect(task) }
                            .draggable(task.uuid.uuidString) {
                                TaskCard(task: task).frame(width: 260)
                            }
                            .contextMenu { TaskMenu(task: task, onEdit: { onSelect(task) }) }
                    }
                }
                .padding(2)

                if tasks.isEmpty {
                    Text("Drop tasks here")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                }
            }

            quickAdd
        }
        .padding(12)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.secondary.opacity(isTargeted ? 0.18 : 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(isTargeted ? Color.accentColor : .clear, lineWidth: 2)
        )
        .dropDestination(for: String.self) { ids, _ in
            context.moveTasks(ids, to: column)
        } isTargeted: { isTargeted = $0 }
    }

    private var header: some View {
        HStack {
            Text(column.name)
                .font(.headline)
            Text("\(tasks.filter { !$0.isCompleted }.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Menu {
                Button("Rename…", systemImage: "pencil", action: onRename)
                Button("Move Left", systemImage: "arrow.left") { onMove(-1) }
                    .disabled(isFirst)
                Button("Move Right", systemImage: "arrow.right") { onMove(1) }
                    .disabled(isLast)
                Divider()
                Button("Delete Column", systemImage: "trash", role: .destructive, action: onDelete)
                    .disabled(!canDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .padding(6)
                    .contentShape(Rectangle())
            }
            .menuIndicator(.hidden)
            .buttonStyle(.borderless)
            .fixedSize()
        }
    }

    private var quickAdd: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .foregroundStyle(.secondary)
            TextField("Add task  (try “p1 tomorrow”)", text: $draft)
                .textFieldStyle(.plain)
                .focused($quickAddFocused)
                .onSubmit(addFromDraft)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.08)))
    }

    private func addFromDraft() {
        let parsed = QuickAddParser.parse(draft)
        guard !parsed.title.isEmpty else { return }
        let task = TaskItem(title: parsed.title, priority: parsed.priority ?? .p3, dueDate: parsed.dueDate)
        context.insert(task)
        task.column = column
        draft = ""
        quickAddFocused = true
    }
}

/// Right-click (Mac) / long-press (iOS) actions for a card.
struct TaskMenu: View {
    let task: TaskItem
    var onEdit: () -> Void
    @Environment(\.modelContext) private var context

    var body: some View {
        Button(task.isCompleted ? "Mark Incomplete" : "Complete",
               systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark.circle") {
            task.setCompleted(!task.isCompleted)
        }
        Button("Edit…", systemImage: "pencil", action: onEdit)

        Menu("Priority") {
            ForEach(Priority.allCases) { priority in
                Button {
                    task.priority = priority
                } label: {
                    Label("\(priority.label) · \(priority.name)",
                          systemImage: task.priority == priority ? "checkmark" : "flag.fill")
                }
            }
        }

        if let columns = task.project?.sortedColumns {
            Menu("Move To") {
                ForEach(columns) { column in
                    Button(column.name) { task.column = column }
                        .disabled(column == task.column)
                }
            }
        }

        Divider()
        Button("Delete", systemImage: "trash", role: .destructive) {
            context.delete(task)
        }
    }
}

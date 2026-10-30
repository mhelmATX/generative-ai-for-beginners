import SwiftUI
import SwiftData

struct BoardView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var context
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    @AppStorage("showCompleted") private var showCompleted = false
    @State private var priorityFilter: Priority?
    @State private var searchText = ""
    @State private var editingTask: TaskItem?
    @State private var renamingColumn: BoardColumn?
    @State private var draftColumnName = ""

    private var isCompact: Bool {
        #if os(iOS)
        sizeClass == .compact
        #else
        false
        #endif
    }

    var body: some View {
        let columns = project.sortedColumns
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 14) {
                ForEach(Array(columns.enumerated()), id: \.element.persistentModelID) { index, column in
                    ColumnView(
                        column: column,
                        tasks: visibleTasks(in: column),
                        isFirst: index == 0,
                        isLast: index == columns.count - 1,
                        canDelete: columns.count > 1,
                        onSelect: { editingTask = $0 },
                        onRename: { startRename(column) },
                        onMove: { moveColumn(column, by: $0) },
                        onDelete: { deleteColumn(column) }
                    )
                    .modifier(ColumnWidth(compact: isCompact))
                }

                Button(action: addColumn) {
                    Label("Add Column", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .frame(width: 200)
            }
            .padding()
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .navigationTitle(project.name)
        .searchable(text: $searchText, prompt: "Search tasks")
        .toolbar { toolbar }
        .sheet(item: $editingTask) { task in
            TaskEditor(task: task)
        }
        .alert("Rename Column", isPresented: isPresented($renamingColumn), presenting: renamingColumn) { column in
            TextField("Name", text: $draftColumnName)
            Button("Save") {
                let name = draftColumnName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty { column.name = name }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: addTask) {
                Label("New Task", systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
        }
        ToolbarItem {
            Menu {
                Picker("Priority", selection: $priorityFilter) {
                    Text("All Priorities").tag(Priority?.none)
                    ForEach(Priority.allCases) { priority in
                        Text("\(priority.label) · \(priority.name)").tag(Optional(priority))
                    }
                }
                Toggle("Show Completed", isOn: $showCompleted)
                Divider()
                Button("Add Column", systemImage: "rectangle.stack.badge.plus", action: addColumn)
            } label: {
                Label(
                    "View Options",
                    systemImage: priorityFilter == nil
                        ? "line.3.horizontal.decrease.circle"
                        : "line.3.horizontal.decrease.circle.fill"
                )
            }
        }
    }

    private func visibleTasks(in column: BoardColumn) -> [TaskItem] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        return (column.tasks ?? [])
            .filter { showCompleted || !$0.isCompleted }
            .filter { priorityFilter == nil || $0.priority == priorityFilter }
            .filter {
                query.isEmpty
                    || $0.title.localizedCaseInsensitiveContains(query)
                    || $0.notes.localizedCaseInsensitiveContains(query)
            }
            .sorted(by: TaskItem.boardOrder)
    }

    private func addTask() {
        guard let column = project.sortedColumns.first else { return }
        // Empty tasks are discarded when the editor closes, so cancelling is free.
        let task = TaskItem(title: "")
        context.insert(task)
        task.column = column
        editingTask = task
    }

    private func addColumn() {
        let column = project.addColumn(named: "New Column", in: context)
        startRename(column)
    }

    private func startRename(_ column: BoardColumn) {
        draftColumnName = column.name
        renamingColumn = column
    }

    private func moveColumn(_ column: BoardColumn, by offset: Int) {
        project.normalizeColumnOrder()
        var columns = project.sortedColumns
        guard let index = columns.firstIndex(of: column) else { return }
        let target = index + offset
        guard columns.indices.contains(target) else { return }
        columns.swapAt(index, target)
        for (order, column) in columns.enumerated() { column.sortOrder = order }
    }

    private func deleteColumn(_ column: BoardColumn) {
        let columns = project.sortedColumns
        guard columns.count > 1, let index = columns.firstIndex(of: column) else { return }
        // Keep the tasks: hand them to the neighbouring column before deleting.
        let fallback = index > 0 ? columns[index - 1] : columns[index + 1]
        for task in column.tasks ?? [] { task.column = fallback }
        context.delete(column)
    }
}

/// Fixed-width columns on Mac and iPad; near full-width, snapping columns on iPhone.
private struct ColumnWidth: ViewModifier {
    let compact: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if compact {
            content.containerRelativeFrame(.horizontal) { length, _ in length - 40 }
        } else {
            content.frame(width: 300)
        }
    }
}

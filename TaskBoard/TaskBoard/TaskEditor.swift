import SwiftUI
import SwiftData

struct TaskEditor: View {
    @Bindable var task: TaskItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Project.sortOrder) private var projects: [Project]

    @State private var deleteOnClose = false
    @FocusState private var titleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task name", text: $task.title)
                        .focused($titleFocused)
                    TextField("Notes", text: $task.notes, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section {
                    Picker("Priority", selection: $task.priority) {
                        ForEach(Priority.allCases) { priority in
                            Text("\(priority.label) \(priority.name)").tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Project", selection: projectID) {
                        ForEach(projects) { project in
                            Text(project.name).tag(Optional(project.persistentModelID))
                        }
                    }

                    Picker("Column", selection: columnID) {
                        ForEach(task.project?.sortedColumns ?? []) { column in
                            Text(column.name).tag(Optional(column.persistentModelID))
                        }
                    }

                    Toggle("Due date", isOn: hasDueDate)
                    if task.dueDate != nil {
                        DatePicker("Date", selection: dueDate, displayedComponents: .date)
                    }

                    Toggle("Completed", isOn: completed)
                }

                Section {
                    Button("Delete Task", role: .destructive) {
                        deleteOnClose = true
                        dismiss()
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(task.title.isEmpty ? "New Task" : "Edit Task")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 500)
        #endif
        .onAppear {
            if task.title.isEmpty { titleFocused = true }
        }
        .onDisappear {
            // Delete after the sheet is gone so no view reads a deleted model.
            let isBlank = task.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if deleteOnClose || isBlank { context.delete(task) }
        }
    }

    private var projectID: Binding<PersistentIdentifier?> {
        Binding(
            get: { task.project?.persistentModelID },
            set: { id in
                guard let project = projects.first(where: { $0.persistentModelID == id }),
                      project != task.project else { return }
                task.column = project.sortedColumns.first
            }
        )
    }

    private var columnID: Binding<PersistentIdentifier?> {
        Binding(
            get: { task.column?.persistentModelID },
            set: { id in
                if let column = task.project?.sortedColumns.first(where: { $0.persistentModelID == id }) {
                    task.column = column
                }
            }
        )
    }

    private var hasDueDate: Binding<Bool> {
        Binding(
            get: { task.dueDate != nil },
            set: { task.dueDate = $0 ? Calendar.current.startOfDay(for: .now) : nil }
        )
    }

    private var dueDate: Binding<Date> {
        Binding(
            get: { task.dueDate ?? .now },
            set: { task.dueDate = Calendar.current.startOfDay(for: $0) }
        )
    }

    private var completed: Binding<Bool> {
        Binding(get: { task.isCompleted }, set: { task.setCompleted($0) })
    }
}

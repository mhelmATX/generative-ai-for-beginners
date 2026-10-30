import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Project.sortOrder) private var projects: [Project]
    @AppStorage("didSeedDefaultProjects") private var didSeed = false

    @State private var selection: PersistentIdentifier?
    @State private var renaming: Project?
    @State private var draftName = ""
    @State private var deleting: Project?

    private var selectedProject: Project? {
        projects.first { $0.persistentModelID == selection }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if let project = selectedProject {
                BoardView(project: project)
                    .id(project.persistentModelID)
            } else {
                ContentUnavailableView(
                    "No Project Selected",
                    systemImage: "rectangle.split.3x1",
                    description: Text("Pick a project from the sidebar.")
                )
            }
        }
        .task {
            if !didSeed {
                SeedData.run(in: context)
                didSeed = true
            }
            if selection == nil {
                let firstProject = try? context.fetch(
                    FetchDescriptor<Project>(sortBy: [SortDescriptor(\.sortOrder)])
                ).first
                selection = firstProject?.persistentModelID
            }
        }
        .alert("Rename Project", isPresented: isPresented($renaming), presenting: renaming) { project in
            TextField("Name", text: $draftName)
            Button("Save") {
                let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty { project.name = name }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Delete project?",
            isPresented: isPresented($deleting),
            presenting: deleting
        ) { project in
            Button("Delete “\(project.name)”", role: .destructive) { delete(project) }
        } message: { _ in
            Text("This deletes the project and all of its tasks.")
        }
    }

    private var sidebar: some View {
        List(selection: $selection) {
            Section("Projects") {
                ForEach(projects) { project in
                    NavigationLink(value: project.persistentModelID) {
                        ProjectRow(project: project)
                    }
                    .contextMenu { projectMenu(for: project) }
                    // Drop a card on a project to move it to that project's first column.
                    .dropDestination(for: String.self) { ids, _ in
                        guard let column = project.sortedColumns.first else { return false }
                        return context.moveTasks(ids, to: column)
                    }
                }
                .onMove(perform: moveProjects)
            }
        }
        .navigationTitle("TaskBoard")
        #if os(macOS)
        .navigationSplitViewColumnWidth(min: 200, ideal: 230)
        #endif
        .toolbar {
            ToolbarItem {
                Button(action: addProject) {
                    Label("New Project", systemImage: "folder.badge.plus")
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
    }

    @ViewBuilder
    private func projectMenu(for project: Project) -> some View {
        Button("Rename…", systemImage: "pencil") { startRename(project) }
        Menu("Color") {
            ForEach(ProjectColor.allCases) { option in
                Button {
                    project.colorName = option.rawValue
                } label: {
                    Label(option.name, systemImage: project.colorName == option.rawValue ? "checkmark.circle.fill" : "circle.fill")
                }
                .tint(option.color)
            }
        }
        Divider()
        Button("Delete…", systemImage: "trash", role: .destructive) { deleting = project }
    }

    private func addProject() {
        let colors = ProjectColor.allCases
        let project = Project.create(
            name: "New Project",
            color: colors[projects.count % colors.count],
            sortOrder: (projects.last?.sortOrder ?? -1) + 1,
            in: context
        )
        selection = project.persistentModelID
        startRename(project)
    }

    private func startRename(_ project: Project) {
        draftName = project.name
        renaming = project
    }

    private func delete(_ project: Project) {
        if selection == project.persistentModelID { selection = nil }
        context.delete(project)
    }

    private func moveProjects(from source: IndexSet, to destination: Int) {
        var reordered = projects
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, project) in reordered.enumerated() { project.sortOrder = index }
    }
}

private struct ProjectRow: View {
    let project: Project

    var body: some View {
        Label {
            Text(project.name)
        } icon: {
            Image(systemName: "circle.fill")
                .foregroundStyle(project.color)
        }
        .badge(project.openTaskCount)
    }
}

/// Bridges an optional "item being acted on" to the Bool that alerts and dialogs want.
func isPresented<T>(_ item: Binding<T?>) -> Binding<Bool> {
    Binding(
        get: { item.wrappedValue != nil },
        set: { if !$0 { item.wrappedValue = nil } }
    )
}

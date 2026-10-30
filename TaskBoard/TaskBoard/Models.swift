import Foundation
import SwiftData
import SwiftUI

// All stored properties have defaults and all relationships are optional so the
// store stays CloudKit-compatible. Turning on iCloud in Xcode is enough to sync.

enum Priority: Int, CaseIterable, Identifiable, Codable {
    case p1 = 1, p2 = 2, p3 = 3

    var id: Int { rawValue }
    var label: String { "P\(rawValue)" }

    var name: String {
        switch self {
        case .p1: "High"
        case .p2: "Medium"
        case .p3: "Low"
        }
    }

    var color: Color {
        switch self {
        case .p1: .red
        case .p2: .orange
        case .p3: .blue
        }
    }
}

enum ProjectColor: String, CaseIterable, Identifiable {
    case red, orange, yellow, green, mint, teal, blue, indigo, purple, pink, gray

    var id: String { rawValue }
    var name: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .mint: .mint
        case .teal: .teal
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        case .gray: .gray
        }
    }
}

@Model
final class Project {
    var name: String = ""
    var colorName: String = ProjectColor.blue.rawValue
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \BoardColumn.project)
    var columns: [BoardColumn]? = []

    init(name: String, colorName: String = ProjectColor.blue.rawValue, sortOrder: Int = 0) {
        self.name = name
        self.colorName = colorName
        self.sortOrder = sortOrder
        self.createdAt = .now
    }

    var color: Color { (ProjectColor(rawValue: colorName) ?? .blue).color }

    var sortedColumns: [BoardColumn] {
        (columns ?? []).sorted { $0.sortOrder < $1.sortOrder }
    }

    var allTasks: [TaskItem] { sortedColumns.flatMap { $0.tasks ?? [] } }
    var openTaskCount: Int { allTasks.filter { !$0.isCompleted }.count }
}

@Model
final class BoardColumn {
    var name: String = ""
    var sortOrder: Int = 0
    var project: Project?

    @Relationship(deleteRule: .cascade, inverse: \TaskItem.column)
    var tasks: [TaskItem]? = []

    init(name: String, sortOrder: Int = 0) {
        self.name = name
        self.sortOrder = sortOrder
    }
}

@Model
final class TaskItem {
    var uuid: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var priorityRaw: Int = Priority.p3.rawValue
    var dueDate: Date?
    var isCompleted: Bool = false
    var completedAt: Date?
    var createdAt: Date = Date()
    var column: BoardColumn?

    init(title: String, notes: String = "", priority: Priority = .p3, dueDate: Date? = nil) {
        self.uuid = UUID()
        self.title = title
        self.notes = notes
        self.priorityRaw = priority.rawValue
        self.dueDate = dueDate
        self.createdAt = .now
    }

    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .p3 }
        set { priorityRaw = newValue.rawValue }
    }

    var project: Project? { column?.project }

    var isOverdue: Bool {
        guard let dueDate, !isCompleted else { return false }
        return dueDate < Calendar.current.startOfDay(for: .now)
    }

    func setCompleted(_ done: Bool) {
        isCompleted = done
        completedAt = done ? .now : nil
    }

    /// Open tasks first, then by priority, then by due date (undated last), then oldest first.
    static func boardOrder(_ a: TaskItem, _ b: TaskItem) -> Bool {
        if a.isCompleted != b.isCompleted { return !a.isCompleted }
        if a.priorityRaw != b.priorityRaw { return a.priorityRaw < b.priorityRaw }
        switch (a.dueDate, b.dueDate) {
        case let (x?, y?) where x != y: return x < y
        case (.some, nil): return true
        case (nil, .some): return false
        default: return a.createdAt < b.createdAt
        }
    }
}

extension Project {
    static let defaultColumnNames = ["To Do", "In Progress", "Waiting On"]

    @discardableResult
    static func create(name: String, color: ProjectColor, sortOrder: Int, in context: ModelContext) -> Project {
        let project = Project(name: name, colorName: color.rawValue, sortOrder: sortOrder)
        context.insert(project)
        var columns: [BoardColumn] = []
        for (index, columnName) in defaultColumnNames.enumerated() {
            let column = BoardColumn(name: columnName, sortOrder: index)
            context.insert(column)
            columns.append(column)
        }
        project.columns = columns
        return project
    }

    @discardableResult
    func addColumn(named name: String, in context: ModelContext) -> BoardColumn {
        let column = BoardColumn(name: name, sortOrder: (sortedColumns.last?.sortOrder ?? -1) + 1)
        context.insert(column)
        column.project = self
        return column
    }

    /// Rewrites sort orders as 0...n so swapping neighbours is always safe.
    func normalizeColumnOrder() {
        for (index, column) in sortedColumns.enumerated() { column.sortOrder = index }
    }
}

extension ModelContext {
    func task(withID id: UUID) -> TaskItem? {
        let descriptor = FetchDescriptor<TaskItem>(predicate: #Predicate { $0.uuid == id })
        return try? fetch(descriptor).first
    }

    /// Handles a drop of dragged task IDs onto a column. Returns true if anything moved.
    func moveTasks(_ ids: [String], to column: BoardColumn) -> Bool {
        var moved = false
        for id in ids.compactMap(UUID.init(uuidString:)) {
            guard let task = task(withID: id) else { continue }
            task.column = column
            moved = true
        }
        return moved
    }
}

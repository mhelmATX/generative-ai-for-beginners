import Foundation
import SwiftData

enum SeedData {
    /// First-launch content: three projects, each with a default board.
    static func run(in context: ModelContext) {
        let work = Project.create(name: "Work", color: .orange, sortOrder: 0, in: context)
        Project.create(name: "Personal", color: .green, sortOrder: 1, in: context)
        Project.create(name: "Career Development", color: .red, sortOrder: 2, in: context)

        guard let todo = work.sortedColumns.first else { return }
        let samples: [(String, Priority)] = [
            ("Try quick add: type “Call Sam p1 tomorrow”", .p1),
            ("Drag this card to another column", .p2),
            ("Right-click (Mac) or long-press (iPhone) a card for more options", .p3),
        ]
        for (title, priority) in samples {
            let task = TaskItem(title: title, priority: priority)
            context.insert(task)
            task.column = todo
        }
    }
}

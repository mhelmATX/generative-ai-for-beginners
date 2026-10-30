import SwiftUI
import SwiftData

@main
struct TaskBoardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Project.self, BoardColumn.self, TaskItem.self])
        #if os(macOS)
        .defaultSize(width: 1200, height: 760)
        #endif
    }
}

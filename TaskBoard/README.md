# TaskBoard

A small Todoist replacement for iPhone, iPad and Mac. One SwiftUI codebase, stored with SwiftData, and it can sync through iCloud.

## What it does

- **Projects** in the sidebar. It starts with Work, Personal and Career Development. Right-click or long-press a project to rename it, change its color or delete it. Drag projects to reorder them.
- **Board view** for every project. Columns start as *To Do / In Progress / Waiting On*. You can add, rename, reorder or delete columns from the `…` menu. Deleting a column moves its tasks to the column next to it.
- **Three priority levels**: P1 High (red), P2 Medium (orange), P3 Low (blue). Within each column, cards sort by priority, then due date.
- **Quick add** at the bottom of every column, with Todoist-style shortcuts:
  - `p1`, `p2`, `p3` (or `!1`, `!2`, `!3`) set the priority
  - `today`, `tomorrow` / `tom`, or a weekday (`friday`) set the due date
  - For example, `Send deck to Sam p1 tomorrow`
- **Drag and drop** cards between columns. Drop a card on a project in the sidebar to move it to that project.
- **Filter** by priority, **show or hide completed** tasks, and **search** titles and notes.
- **Keyboard shortcuts (Mac):** ⌘N adds a task, ⇧⌘N adds a project.

## Run it

You need Xcode 16 or later. The app runs on iOS 17+ and macOS 14+.

1. Open `TaskBoard.xcodeproj`.
2. Select the **TaskBoard** target, open **Signing & Capabilities**, and pick your Team. Change the bundle ID from `com.example.TaskBoard` to something you own.
3. Pick a run destination (**My Mac**, an iPhone simulator, or your phone) and press ⌘R.

## Sync between iPhone and Mac

Out of the box, each device keeps its own local data. To sync through iCloud:

1. In **Signing & Capabilities**, click **+ Capability** and add **iCloud**. Check **CloudKit** and add a container, for example `iCloud.com.yourname.TaskBoard`.
2. Add **Background Modes** and check **Remote notifications**. This one is for iOS.
3. Build to both devices with the same Apple ID signed in.

The data model is already CloudKit-compatible, so no code changes are needed. One catch: each device creates the three starter projects on first launch. After turning on sync, delete the duplicates once.

## Code layout

| File | What it holds |
|---|---|
| `Models.swift` | `Project` → `BoardColumn` → `TaskItem`, plus `Priority` |
| `ContentView.swift` | Sidebar and project management |
| `BoardView.swift` | Horizontal board, toolbar, filters, column actions |
| `ColumnView.swift` | One column: quick add, drop target, card context menu |
| `TaskCard.swift` | The card |
| `TaskEditor.swift` | Edit sheet: notes, priority, project/column, due date |
| `QuickAddParser.swift` | `p1 tomorrow` parsing |

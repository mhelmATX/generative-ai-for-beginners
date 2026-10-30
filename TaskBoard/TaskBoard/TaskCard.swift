import SwiftUI

struct TaskCard: View {
    let task: TaskItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                withAnimation { task.setCompleted(!task.isCompleted) }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.priority.color)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? "Mark incomplete" : "Complete")

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if let due = task.dueDate {
                        Label(Self.dueLabel(due), systemImage: "calendar")
                            .foregroundStyle(task.isOverdue ? .red : .secondary)
                    }
                    Spacer(minLength: 0)
                    Label(task.priority.label, systemImage: "flag.fill")
                        .foregroundStyle(task.priority.color)
                }
                .font(.caption)
                .labelStyle(.titleAndIcon)
            }
        }
        .padding(10)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
        .opacity(task.isCompleted ? 0.6 : 1)
    }

    static func dueLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }
}

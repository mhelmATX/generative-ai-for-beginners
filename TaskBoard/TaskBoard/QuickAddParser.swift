import Foundation

/// Todoist-style quick add: "Send deck to Sam p1 tomorrow" becomes
/// title "Send deck to Sam", priority P1, due tomorrow.
enum QuickAddParser {
    struct Result: Equatable {
        var title: String
        var priority: Priority?
        var dueDate: Date?
    }

    private static let weekdays = [
        "sunday": 1, "monday": 2, "tuesday": 3, "wednesday": 4,
        "thursday": 5, "friday": 6, "saturday": 7,
    ]

    static func parse(_ input: String, now: Date = .now, calendar: Calendar = .current) -> Result {
        let today = calendar.startOfDay(for: now)
        var priority: Priority?
        var dueDate: Date?
        var kept: [Substring] = []

        for word in input.split(separator: " ", omittingEmptySubsequences: true) {
            switch word.lowercased() {
            case "p1", "!1": priority = .p1
            case "p2", "!2": priority = .p2
            case "p3", "!3": priority = .p3
            case "today", "tod": dueDate = today
            case "tomorrow", "tom": dueDate = calendar.date(byAdding: .day, value: 1, to: today)
            case let name where weekdays[name] != nil:
                let next = calendar.nextDate(
                    after: today,
                    matching: DateComponents(weekday: weekdays[name]),
                    matchingPolicy: .nextTime
                )
                dueDate = next.map { calendar.startOfDay(for: $0) }
            default:
                kept.append(word)
            }
        }

        return Result(title: kept.joined(separator: " "), priority: priority, dueDate: dueDate)
    }
}

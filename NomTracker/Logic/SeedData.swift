import Foundation
import SwiftData

enum SeedData {
    static func defaultMacros() -> [Macro] {
        [
            Macro(name: "Calories", unit: "kcal", dailyGoal: 2000, goalKind: .atMost, sortOrder: 0),
            Macro(name: "Protein", unit: "g", dailyGoal: 120, goalKind: .atLeast, sortOrder: 1),
            Macro(name: "Carbs", unit: "g", dailyGoal: 250, goalKind: .atMost, sortOrder: 2),
            Macro(name: "Fat", unit: "g", dailyGoal: 70, goalKind: .atMost, sortOrder: 3),
            Macro(name: "Fiber", unit: "g", dailyGoal: 30, goalKind: .atLeast, sortOrder: 4),
            Macro(name: "Sugar", unit: "g", dailyGoal: 50, goalKind: .atMost, isTracked: false, sortOrder: 5),
            Macro(name: "Sodium", unit: "mg", dailyGoal: 2300, goalKind: .atMost, isTracked: false, sortOrder: 6),
        ]
    }

    /// Inserts the default macros the first time the app runs.
    static func seedIfNeeded(_ context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Macro>())) ?? 0
        guard count == 0 else { return }
        defaultMacros().forEach { context.insert($0) }
    }
}

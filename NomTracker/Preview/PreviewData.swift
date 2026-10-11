import Foundation
import SwiftData

/// In-memory store with default macros, a few saved foods and ~90 days of entries.
@MainActor
enum PreviewData {
    static func makeContainer() -> ModelContainer {
        let container = try! ModelContainer(
            for: Macro.self, SavedFood.self, FoodEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let macros = SeedData.defaultMacros()
        macros.forEach { context.insert($0) }
        let ids = Dictionary(uniqueKeysWithValues: macros.map { ($0.name, $0.key) })

        func values(_ kcal: Double, _ protein: Double, _ carbs: Double, _ fat: Double, _ fiber: Double, _ sugar: Double) -> [String: Double] {
            [ids["Calories"]!: kcal, ids["Protein"]!: protein, ids["Carbs"]!: carbs,
             ids["Fat"]!: fat, ids["Fiber"]!: fiber, ids["Sugar"]!: sugar]
        }

        let meals: [(String, [String: Double])] = [
            ("Oatmeal with berries", values(350, 12, 60, 7, 9, 14)),
            ("Chicken salad", values(520, 42, 20, 28, 6, 6)),
            ("Salmon, rice and broccoli", values(680, 45, 70, 22, 7, 4)),
            ("Greek yogurt", values(150, 17, 8, 4, 0, 7)),
            ("Burrito bowl", values(780, 38, 85, 30, 14, 5)),
            ("Protein shake", values(210, 30, 9, 4, 3, 3)),
        ]
        for (name, perServing) in meals.prefix(3) {
            context.insert(SavedFood(name: name, servingDescription: "1 bowl", valuesPerServing: perServing))
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        for offset in 0..<90 {
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let mealCount = 2 + offset % 3
            for slot in 0..<mealCount {
                let (name, base) = meals[(offset + slot * 2) % meals.count]
                let time = calendar.date(byAdding: .hour, value: 8 + slot * 4, to: day)!
                guard time <= .now else { continue }
                let servings = slot == 2 && offset % 4 == 0 ? 1.5 : 1
                context.insert(FoodEntry(timestamp: time, name: name, servings: servings, values: base.mapValues { $0 * servings }))
            }
        }
        return container
    }
}

import Foundation
import SwiftData

/// One logged food. `values` holds the totals at the time of logging, so later edits
/// to a saved food don't change history.
@Model
final class FoodEntry: MacroValued {
    var timestamp: Date
    var name: String
    var servings: Double
    /// Total amount for this entry (all servings), keyed by `Macro.key`.
    var values: [String: Double]

    init(timestamp: Date = .now, name: String, servings: Double = 1, values: [String: Double] = [:]) {
        self.timestamp = timestamp
        self.name = name
        self.servings = servings
        self.values = values
    }
}

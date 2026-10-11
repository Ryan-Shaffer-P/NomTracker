import Foundation
import SwiftData

/// Whether a daily goal is a target to reach (protein, fiber) or a limit to stay under (calories, sugar).
enum GoalKind: String, Codable, CaseIterable, Identifiable {
    case atLeast
    case atMost

    var id: String { rawValue }

    var label: String {
        switch self {
        case .atLeast: "At least"
        case .atMost: "At most"
        }
    }
}

/// A nutrient the user can track, such as calories or protein.
@Model
final class Macro {
    @Attribute(.unique) var id: UUID
    var name: String
    var unit: String
    /// Goal per day. Week, month and year goals are scaled from this.
    var dailyGoal: Double?
    var goalKindRaw: String
    var isTracked: Bool
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        unit: String,
        dailyGoal: Double? = nil,
        goalKind: GoalKind = .atLeast,
        isTracked: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.unit = unit
        self.dailyGoal = dailyGoal
        self.goalKindRaw = goalKind.rawValue
        self.isTracked = isTracked
        self.sortOrder = sortOrder
    }

    var goalKind: GoalKind {
        get { GoalKind(rawValue: goalKindRaw) ?? .atLeast }
        set { goalKindRaw = newValue.rawValue }
    }

    /// Key used for this macro in the `values` dictionaries of entries and saved foods.
    var key: String { id.uuidString }
}

import Foundation
import SwiftData

/// A food saved for quick re-logging.
@Model
final class SavedFood {
    var name: String
    var servingDescription: String
    /// Amount per serving, keyed by `Macro.key`.
    var valuesPerServing: [String: Double]
    var createdAt: Date

    init(name: String, servingDescription: String = "", valuesPerServing: [String: Double] = [:]) {
        self.name = name
        self.servingDescription = servingDescription
        self.valuesPerServing = valuesPerServing
        self.createdAt = .now
    }
}

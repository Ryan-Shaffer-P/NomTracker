import SwiftUI

extension GoalStatus {
    var color: Color {
        switch self {
        case .met: .green
        case .under: .blue
        case .over: .red
        case .noGoal: .accentColor
        }
    }
}

/// Name, total vs. goal, a progress bar and how much is left or over.
struct MacroProgressRow: View {
    let title: String
    let total: Double
    let goal: Double?
    let unit: String
    let kind: GoalKind
    /// Show the total as a percentage of the goal.
    var showsPercent = false

    var body: some View {
        let status = Aggregator.status(total: total, goal: goal, kind: kind)
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.headline)
                Spacer()
                Group {
                    if let goal, goal > 0 {
                        Text("\(total.macroFormatted) / \(goal.macroFormatted) \(unit)")
                    } else {
                        Text("\(total.macroFormatted) \(unit)")
                    }
                }
                .monospacedDigit()
            }
            if let goal, goal > 0 {
                ProgressView(value: min(total / goal, 1))
                    .tint(status.color)
                HStack {
                    Text(Self.remainingText(total: total, goal: goal, unit: unit, kind: kind))
                        .foregroundStyle(status == .over ? .red : .secondary)
                    Spacer()
                    if showsPercent {
                        Text((total / goal).formatted(.percent.precision(.fractionLength(0))))
                            .fontWeight(.semibold)
                            .foregroundStyle(status.color)
                            .monospacedDigit()
                    }
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 2)
    }

    static func remainingText(total: Double, goal: Double, unit: String, kind: GoalKind) -> String {
        switch kind {
        case .atLeast:
            total >= goal ? "Goal met" : "\((goal - total).macroFormatted) \(unit) to go"
        case .atMost:
            total > goal ? "\((total - goal).macroFormatted) \(unit) over" : "\((goal - total).macroFormatted) \(unit) left"
        }
    }
}

/// A food name with a one-line summary of its tracked macro values.
struct FoodSummaryRow: View {
    let name: String
    var detail: String = ""
    let values: [String: Double]
    let macros: [Macro]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text(name).foregroundStyle(.primary)
                if !detail.isEmpty {
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
            }
            Text(summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var summary: String {
        macros
            .map { "\($0.name) \((values[$0.key] ?? 0).macroFormatted)" }
            .joined(separator: " · ")
    }
}

#Preview {
    List {
        MacroProgressRow(title: "Calories", total: 1450, goal: 2000, unit: "kcal", kind: .atMost)
        MacroProgressRow(title: "Protein", total: 130, goal: 120, unit: "g", kind: .atLeast)
        MacroProgressRow(title: "Sugar", total: 62, goal: 50, unit: "g", kind: .atMost)
        MacroProgressRow(title: "Water", total: 3, goal: nil, unit: "cups", kind: .atLeast)
    }
}

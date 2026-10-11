import SwiftUI

/// Period total vs. scaled goal, average per day, and a small bar chart.
struct MacroCard: View {
    let macro: Macro
    let entries: [FoodEntry]
    let period: Period
    let calendar: Calendar

    var body: some View {
        let interval = period.interval(in: calendar)
        let total = Aggregator.total(entries, macroID: macro.id, in: interval)
        let goal = Aggregator.periodGoal(dailyGoal: macro.dailyGoal, days: period.dayCount(in: calendar))
        let points = Aggregator.chartSeries(entries, macroID: macro.id, period: period, calendar: calendar)

        VStack(alignment: .leading, spacing: 8) {
            MacroProgressRow(title: macro.name, total: total, goal: goal, unit: macro.unit, kind: macro.goalKind)
            if period.scale != .day {
                Text(averageText(total: total))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if points.count > 1 {
                MacroBarChart(
                    points: points,
                    goal: macro.dailyGoal,
                    kind: macro.goalKind,
                    binUnit: period.scale.chartBinUnit,
                    domain: period.chartInterval(in: calendar),
                    compact: true
                )
                .frame(height: 44)
            }
        }
        .padding(.vertical, 4)
    }

    private func averageText(total: Double) -> String {
        let days = period.elapsedDayCount(in: calendar)
        guard days > 0 else { return "No days yet" }
        var text = "Avg \((total / Double(days)).macroFormatted) \(macro.unit)/day"
        if let daily = macro.dailyGoal {
            text += " · goal \(daily.macroFormatted) \(macro.unit)/day"
        }
        return text
    }
}

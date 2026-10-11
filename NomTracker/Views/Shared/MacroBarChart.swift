import Charts
import SwiftUI

/// Bars colored by goal status, with a dashed line at the daily goal.
struct MacroBarChart: View {
    let points: [SeriesPoint]
    let goal: Double?
    let kind: GoalKind
    let binUnit: Calendar.Component
    let domain: DateInterval
    var compact = false
    var selection: Binding<Date?>? = nil
    var calendar: Calendar = .current

    var body: some View {
        let chart = Chart {
            ForEach(points) { point in
                BarMark(
                    x: .value("Date", point.date, unit: binUnit),
                    y: .value("Amount", point.value)
                )
                .foregroundStyle(Aggregator.status(total: point.value, goal: goal, kind: kind).color)
                .opacity(isDimmed(point) ? 0.35 : 1)
            }
            if let goal, goal > 0 {
                RuleMark(y: .value("Goal", goal))
                    .foregroundStyle(Color.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
        }
        .chartXScale(domain: domain.start...domain.end)

        if compact {
            chart
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
        } else if let selection {
            chart.chartXSelection(value: selection)
        } else {
            chart
        }
    }

    private func isDimmed(_ point: SeriesPoint) -> Bool {
        guard let selected = selection?.wrappedValue else { return false }
        return !calendar.isDate(point.date, equalTo: selected, toGranularity: binUnit)
    }
}

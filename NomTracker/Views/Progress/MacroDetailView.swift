import SwiftData
import SwiftUI

/// Full chart and summary stats for one macro over a week, month or year.
struct MacroDetailView: View {
    let macro: Macro

    @AppStorage(AppSettings.firstWeekdayKey) private var firstWeekday = Calendar.current.firstWeekday
    @State private var period: Period

    init(macro: Macro, initialPeriod: Period) {
        self.macro = macro
        // A single day is charted as its week.
        let scale: PeriodScale = initialPeriod.scale == .day ? .week : initialPeriod.scale
        _period = State(initialValue: Period(scale: scale, anchor: initialPeriod.anchor))
    }

    private var calendar: Calendar { .app(firstWeekday: firstWeekday) }

    var body: some View {
        EntriesQuery(interval: period.chartInterval(in: calendar)) { entries in
            MacroDetailContent(macro: macro, entries: entries, period: $period, calendar: calendar)
        }
        .navigationTitle(macro.name)
    }
}

private struct MacroDetailContent: View {
    let macro: Macro
    let entries: [FoodEntry]
    @Binding var period: Period
    let calendar: Calendar

    @State private var selectedDate: Date?

    var body: some View {
        let interval = period.chartInterval(in: calendar)
        let binUnit = period.scale.chartBinUnit
        let points = Aggregator.chartSeries(entries, macroID: macro.id, period: period, calendar: calendar)
        let daily = period.scale == .year
            ? Aggregator.dailySeries(entries, macroID: macro.id, in: interval, calendar: calendar)
            : points
        let total = daily.reduce(0) { $0 + $1.value }
        let best = daily.max { $0.value < $1.value }
        let daysMet = daily.filter {
            $0.value > 0 && Aggregator.status(total: $0.value, goal: macro.dailyGoal, kind: macro.goalKind) == .met
        }.count

        List {
            Section {
                PeriodNavigator(period: $period, calendar: calendar, scales: [.week, .month, .year])
            }
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(selectionText(points: points, binUnit: binUnit))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    MacroBarChart(
                        points: points,
                        goal: macro.dailyGoal,
                        kind: macro.goalKind,
                        binUnit: binUnit,
                        domain: interval,
                        selection: $selectedDate,
                        calendar: calendar
                    )
                    .frame(height: 240)
                }
                .padding(.vertical, 8)
            } footer: {
                Text(period.scale == .year
                     ? "Each bar is the average per day for that month. The dashed line is your daily goal."
                     : "The dashed line is your daily goal.")
            }
            Section("Summary") {
                LabeledContent("Total", value: "\(total.macroFormatted) \(macro.unit)")
                LabeledContent("Average per day", value: daily.isEmpty ? "–" : "\((total / Double(daily.count)).macroFormatted) \(macro.unit)")
                if let best, best.value > 0 {
                    LabeledContent("Highest day", value: "\(best.value.macroFormatted) \(macro.unit) · \(best.date.formatted(.dateTime.month(.abbreviated).day()))")
                }
                if let goal = macro.dailyGoal {
                    LabeledContent("Daily goal", value: "\(macro.goalKind.label.lowercased()) \(goal.macroFormatted) \(macro.unit)")
                    LabeledContent("Days goal met", value: "\(daysMet) of \(daily.count)")
                }
            }
        }
        .onChange(of: period) { selectedDate = nil }
    }

    private func selectionText(points: [SeriesPoint], binUnit: Calendar.Component) -> String {
        guard let selectedDate,
              let point = points.first(where: { calendar.isDate($0.date, equalTo: selectedDate, toGranularity: binUnit) })
        else { return "Tap or drag on the chart to see values" }
        if binUnit == .month {
            return "\(point.date.formatted(.dateTime.month(.wide))): avg \(point.value.macroFormatted) \(macro.unit)/day"
        }
        return "\(point.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())): \(point.value.macroFormatted) \(macro.unit)"
    }
}

#Preview {
    let container = PreviewData.makeContainer()
    let macro = try! container.mainContext.fetch(FetchDescriptor<Macro>(sortBy: [SortDescriptor(\.sortOrder)])).first!
    return NavigationStack {
        MacroDetailView(macro: macro, initialPeriod: Period(scale: .month, anchor: .now))
    }
    .modelContainer(container)
}

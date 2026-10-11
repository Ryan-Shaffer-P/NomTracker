import Foundation

/// Anything with a time and per-macro amounts. `FoodEntry` conforms; tests use a plain struct.
protocol MacroValued {
    var timestamp: Date { get }
    var values: [String: Double] { get }
}

extension MacroValued {
    func value(for macroID: UUID) -> Double {
        values[macroID.uuidString] ?? 0
    }
}

enum GoalStatus {
    case met, under, over, noGoal
}

struct SeriesPoint: Identifiable, Equatable {
    let date: Date
    let value: Double
    var id: Date { date }
}

enum Aggregator {
    static func entries<E: MacroValued>(_ entries: [E], in interval: DateInterval) -> [E] {
        entries.filter { $0.timestamp >= interval.start && $0.timestamp < interval.end }
    }

    static func total<E: MacroValued>(_ entries: [E], macroID: UUID, in interval: DateInterval) -> Double {
        self.entries(entries, in: interval).reduce(0) { $0 + $1.value(for: macroID) }
    }

    /// One point per day of `interval` that has started by `now`.
    static func dailySeries<E: MacroValued>(
        _ entries: [E], macroID: UUID, in interval: DateInterval, calendar: Calendar, now: Date = .now
    ) -> [SeriesPoint] {
        var byDay: [Date: Double] = [:]
        for entry in self.entries(entries, in: interval) {
            byDay[calendar.startOfDay(for: entry.timestamp), default: 0] += entry.value(for: macroID)
        }
        return Period.dayStarts(in: interval, calendar: calendar)
            .filter { $0 <= now }
            .map { SeriesPoint(date: $0, value: byDay[$0] ?? 0) }
    }

    /// One point per month of `interval` that has started by `now`, valued at the average per elapsed day.
    static func monthlyAverages<E: MacroValued>(
        _ entries: [E], macroID: UUID, in interval: DateInterval, calendar: Calendar, now: Date = .now
    ) -> [SeriesPoint] {
        var points: [SeriesPoint] = []
        var start = interval.start
        while start < interval.end && start <= now {
            let month = calendar.dateInterval(of: .month, for: start)!
            let days = Period.elapsedDays(in: month, calendar: calendar, now: now)
            let total = total(entries, macroID: macroID, in: month)
            points.append(SeriesPoint(date: month.start, value: days > 0 ? total / Double(days) : 0))
            start = month.end
        }
        return points
    }

    /// Chart points for a period: daily bars, or monthly averages for a year.
    static func chartSeries<E: MacroValued>(
        _ entries: [E], macroID: UUID, period: Period, calendar: Calendar, now: Date = .now
    ) -> [SeriesPoint] {
        let interval = period.chartInterval(in: calendar)
        return period.scale == .year
            ? monthlyAverages(entries, macroID: macroID, in: interval, calendar: calendar, now: now)
            : dailySeries(entries, macroID: macroID, in: interval, calendar: calendar, now: now)
    }

    static func periodGoal(dailyGoal: Double?, days: Int) -> Double? {
        dailyGoal.map { $0 * Double(days) }
    }

    static func status(total: Double, goal: Double?, kind: GoalKind) -> GoalStatus {
        guard let goal, goal > 0 else { return .noGoal }
        switch kind {
        case .atLeast: return total >= goal ? .met : .under
        case .atMost: return total > goal ? .over : .met
        }
    }
}

extension Double {
    /// Whole numbers stay whole; otherwise one decimal place.
    var macroFormatted: String {
        formatted(.number.precision(.fractionLength(0...1)))
    }
}

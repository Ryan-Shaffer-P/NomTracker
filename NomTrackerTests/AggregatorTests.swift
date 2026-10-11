import Foundation
import Testing
@testable import NomTracker

private struct TestEntry: MacroValued {
    var timestamp: Date
    var values: [String: Double]
}

struct AggregatorTests {
    let calories = UUID()
    let protein = UUID()
    let calendar = utcCalendar()

    private func entry(_ day: Int, hour: Int = 12, kcal: Double, protein p: Double = 0, month: Int = 10) -> TestEntry {
        TestEntry(
            timestamp: date(2026, month, day, hour: hour),
            values: [calories.uuidString: kcal, protein.uuidString: p]
        )
    }

    @Test func totalsOnlyCountEntriesInsideInterval() {
        let entries = [
            entry(10, hour: 23, kcal: 999),   // day before
            entry(11, hour: 0, kcal: 300, protein: 20),
            entry(11, hour: 18, kcal: 700, protein: 40),
            entry(12, hour: 0, kcal: 999),    // exactly at end: excluded
        ]
        let day = Period(scale: .day, anchor: date(2026, 10, 11)).interval(in: calendar)
        #expect(Aggregator.total(entries, macroID: calories, in: day) == 1000)
        #expect(Aggregator.total(entries, macroID: protein, in: day) == 60)
        #expect(Aggregator.total(entries, macroID: UUID(), in: day) == 0)
    }

    @Test func periodGoalScalesDailyGoal() {
        #expect(Aggregator.periodGoal(dailyGoal: 2000, days: 7) == 14000)
        #expect(Aggregator.periodGoal(dailyGoal: 30, days: 31) == 930)
        #expect(Aggregator.periodGoal(dailyGoal: nil, days: 7) == nil)
    }

    @Test func status() {
        #expect(Aggregator.status(total: 100, goal: 120, kind: .atLeast) == .under)
        #expect(Aggregator.status(total: 120, goal: 120, kind: .atLeast) == .met)
        #expect(Aggregator.status(total: 2000, goal: 2000, kind: .atMost) == .met)
        #expect(Aggregator.status(total: 2100, goal: 2000, kind: .atMost) == .over)
        #expect(Aggregator.status(total: 50, goal: nil, kind: .atMost) == .noGoal)
        #expect(Aggregator.status(total: 50, goal: 0, kind: .atLeast) == .noGoal)
    }

    @Test func dailySeriesStopsAtToday() {
        let entries = [entry(5, kcal: 500), entry(5, hour: 19, kcal: 250), entry(7, kcal: 1800)]
        let week = DateInterval(start: date(2026, 10, 4), end: date(2026, 10, 11))
        let series = Aggregator.dailySeries(entries, macroID: calories, in: week, calendar: calendar, now: date(2026, 10, 7, hour: 9))
        #expect(series.map(\.value) == [0, 750, 0, 1800])
        #expect(series.first?.date == date(2026, 10, 4))
    }

    @Test func monthlyAveragesUseElapsedDays() {
        let entries = [
            entry(1, kcal: 3100, month: 1),     // January: 3100 / 31 days
            entry(10, kcal: 1500, month: 3),
            entry(14, kcal: 1500, month: 3),   // March: 3000 / 15 elapsed days
        ]
        let year = Period(scale: .year, anchor: date(2026, 1, 1)).interval(in: calendar)
        let series = Aggregator.monthlyAverages(entries, macroID: calories, in: year, calendar: calendar, now: date(2026, 3, 15, hour: 8))
        #expect(series.map(\.value) == [100, 0, 200])
        #expect(series.map(\.date) == [date(2026, 1, 1), date(2026, 2, 1), date(2026, 3, 1)])
    }
}

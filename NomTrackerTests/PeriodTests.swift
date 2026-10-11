import Foundation
import Testing
@testable import NomTracker

func utcCalendar(firstWeekday: Int = 1) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    calendar.firstWeekday = firstWeekday
    return calendar
}

func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, calendar: Calendar = utcCalendar()) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
}

struct PeriodTests {
    // Oct 14 2026 is a Wednesday.
    @Test func weekStartsOnSunday() {
        let calendar = utcCalendar(firstWeekday: 1)
        let interval = Period(scale: .week, anchor: date(2026, 10, 14)).interval(in: calendar)
        #expect(interval.start == date(2026, 10, 11))
        #expect(interval.end == date(2026, 10, 18))
    }

    @Test func weekStartsOnMonday() {
        let calendar = utcCalendar(firstWeekday: 2)
        let interval = Period(scale: .week, anchor: date(2026, 10, 14)).interval(in: calendar)
        #expect(interval.start == date(2026, 10, 12))
        #expect(Period(scale: .week, anchor: date(2026, 10, 14)).dayCount(in: calendar) == 7)
    }

    @Test(arguments: [
        (2026, 2, 28), (2028, 2, 29), (2026, 10, 31), (2026, 4, 30),
    ])
    func monthLength(year: Int, month: Int, days: Int) {
        let period = Period(scale: .month, anchor: date(year, month, 15))
        #expect(period.dayCount(in: utcCalendar()) == days)
    }

    @Test func yearLength() {
        #expect(Period(scale: .year, anchor: date(2026, 6, 1)).dayCount(in: utcCalendar()) == 365)
        #expect(Period(scale: .year, anchor: date(2028, 6, 1)).dayCount(in: utcCalendar()) == 366)
    }

    @Test func nextMonthFromJan31IsFebruary() {
        let calendar = utcCalendar()
        let next = Period(scale: .month, anchor: date(2026, 1, 31)).next(in: calendar)
        #expect(next.interval(in: calendar).start == date(2026, 2, 1))
        #expect(next.previous(in: calendar).interval(in: calendar).start == date(2026, 1, 1))
    }

    @Test func elapsedDays() {
        let calendar = utcCalendar()
        let october = Period(scale: .month, anchor: date(2026, 10, 1))
        let now = date(2026, 10, 11, hour: 12)
        #expect(october.elapsedDayCount(in: calendar, now: now) == 11)
        #expect(Period(scale: .month, anchor: date(2026, 9, 1)).elapsedDayCount(in: calendar, now: now) == 30)
        #expect(Period(scale: .month, anchor: date(2026, 11, 1)).elapsedDayCount(in: calendar, now: now) == 0)
    }

    @Test func dayIsChartedWithItsWeek() {
        let calendar = utcCalendar(firstWeekday: 2)
        let chart = Period(scale: .day, anchor: date(2026, 10, 14)).chartInterval(in: calendar)
        #expect(chart.start == date(2026, 10, 12))
        #expect(chart.end == date(2026, 10, 19))
    }
}

import Foundation

enum PeriodScale: String, CaseIterable, Identifiable {
    case day, week, month, year

    var id: String { rawValue }

    var title: String { rawValue.capitalized }

    var component: Calendar.Component {
        switch self {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
    }

    /// Width of one bar when charting this scale: days, or months for a year.
    var chartBinUnit: Calendar.Component {
        self == .year ? .month : .day
    }
}

/// A calendar day, week, month or year, identified by any date inside it.
struct Period: Equatable {
    var scale: PeriodScale
    var anchor: Date

    func interval(in calendar: Calendar) -> DateInterval {
        calendar.dateInterval(of: scale.component, for: anchor)!
    }

    /// The range charted for this period. A single day is charted with the rest of its week.
    func chartInterval(in calendar: Calendar) -> DateInterval {
        scale == .day ? calendar.dateInterval(of: .weekOfYear, for: anchor)! : interval(in: calendar)
    }

    func dayCount(in calendar: Calendar) -> Int {
        Self.days(in: interval(in: calendar), calendar: calendar)
    }

    func elapsedDayCount(in calendar: Calendar, now: Date = .now) -> Int {
        Self.elapsedDays(in: interval(in: calendar), calendar: calendar, now: now)
    }

    func contains(_ date: Date, in calendar: Calendar) -> Bool {
        let interval = interval(in: calendar)
        return date >= interval.start && date < interval.end
    }

    func next(in calendar: Calendar) -> Period {
        Period(scale: scale, anchor: calendar.date(byAdding: scale.component, value: 1, to: anchor)!)
    }

    func previous(in calendar: Calendar) -> Period {
        Period(scale: scale, anchor: calendar.date(byAdding: scale.component, value: -1, to: anchor)!)
    }

    func label(in calendar: Calendar) -> String {
        switch scale {
        case .day:
            if calendar.isDateInToday(anchor) { return "Today" }
            if calendar.isDateInYesterday(anchor) { return "Yesterday" }
            return anchor.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        case .week:
            let interval = interval(in: calendar)
            let last = calendar.date(byAdding: .day, value: -1, to: interval.end)!
            let style = Date.FormatStyle.dateTime.month(.abbreviated).day()
            return "\(interval.start.formatted(style)) – \(last.formatted(style))"
        case .month:
            return anchor.formatted(.dateTime.month(.wide).year())
        case .year:
            return anchor.formatted(.dateTime.year())
        }
    }

    static func days(in interval: DateInterval, calendar: Calendar) -> Int {
        calendar.dateComponents([.day], from: interval.start, to: interval.end).day ?? 0
    }

    /// Days of `interval` that have started by `now`, counting today.
    static func elapsedDays(in interval: DateInterval, calendar: Calendar, now: Date) -> Int {
        if now < interval.start { return 0 }
        if now >= interval.end { return days(in: interval, calendar: calendar) }
        let elapsed = DateInterval(start: interval.start, end: calendar.startOfDay(for: now))
        return days(in: elapsed, calendar: calendar) + 1
    }

    static func dayStarts(in interval: DateInterval, calendar: Calendar) -> [Date] {
        var result: [Date] = []
        var day = calendar.startOfDay(for: interval.start)
        while day < interval.end {
            result.append(day)
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }
        return result
    }
}

enum AppSettings {
    static let firstWeekdayKey = "firstWeekday"
}

extension Calendar {
    /// The current calendar with the user's chosen first day of the week.
    static func app(firstWeekday: Int) -> Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = firstWeekday
        return calendar
    }
}

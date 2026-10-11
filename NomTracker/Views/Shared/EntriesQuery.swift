import SwiftData
import SwiftUI

/// Fetches the food entries inside `interval` and hands them to `content`.
/// Wrapping the query in its own view lets the date range change at runtime.
struct EntriesQuery<Content: View>: View {
    @Query private var entries: [FoodEntry]
    private let content: ([FoodEntry]) -> Content

    init(interval: DateInterval, @ViewBuilder content: @escaping ([FoodEntry]) -> Content) {
        let start = interval.start
        let end = interval.end
        _entries = Query(
            filter: #Predicate<FoodEntry> { $0.timestamp >= start && $0.timestamp < end },
            sort: \FoodEntry.timestamp
        )
        self.content = content
    }

    var body: some View {
        content(entries)
    }
}

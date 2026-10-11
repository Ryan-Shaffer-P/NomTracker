import SwiftData
import SwiftUI

struct ProgressScreen: View {
    @AppStorage(AppSettings.firstWeekdayKey) private var firstWeekday = Calendar.current.firstWeekday
    @State private var period = Period(scale: .week, anchor: .now)

    private var calendar: Calendar { .app(firstWeekday: firstWeekday) }

    var body: some View {
        NavigationStack {
            EntriesQuery(interval: period.chartInterval(in: calendar)) { entries in
                PeriodSummaryList(entries: entries, period: $period, calendar: calendar)
            }
            .navigationTitle("Progress")
            .navigationDestination(for: Macro.self) { macro in
                MacroDetailView(macro: macro, initialPeriod: period)
            }
        }
    }
}

private struct PeriodSummaryList: View {
    let entries: [FoodEntry]
    @Binding var period: Period
    let calendar: Calendar

    @Query(filter: #Predicate<Macro> { $0.isTracked == true }, sort: \Macro.sortOrder)
    private var macros: [Macro]

    var body: some View {
        List {
            Section {
                PeriodNavigator(period: $period, calendar: calendar)
            }
            if macros.isEmpty {
                Text("No macros are tracked. Turn some on in Settings.")
                    .foregroundStyle(.secondary)
            }
            ForEach(macros) { macro in
                Section {
                    NavigationLink(value: macro) {
                        MacroCard(macro: macro, entries: entries, period: period, calendar: calendar)
                    }
                }
            }
        }
        .listSectionSpacing(.compact)
    }
}

#Preview {
    ProgressScreen()
        .modelContainer(PreviewData.makeContainer())
}

import SwiftData
import SwiftUI

struct TodayView: View {
    @AppStorage(AppSettings.firstWeekdayKey) private var firstWeekday = Calendar.current.firstWeekday
    @State private var period = Period(scale: .day, anchor: .now)
    @State private var showingAdd = false

    private var calendar: Calendar { .app(firstWeekday: firstWeekday) }

    var body: some View {
        NavigationStack {
            EntriesQuery(interval: period.interval(in: calendar)) { entries in
                DayList(entries: entries, period: $period, calendar: calendar)
            }
            .navigationTitle("Log")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("Add Food", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddEntryView(day: period.anchor)
            }
        }
    }
}

private struct DayList: View {
    let entries: [FoodEntry]
    @Binding var period: Period
    let calendar: Calendar

    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Macro> { $0.isTracked == true }, sort: \Macro.sortOrder)
    private var macros: [Macro]
    @State private var editing: FoodEntry?

    var body: some View {
        List {
            Section {
                PeriodNavigator(period: $period, calendar: calendar, scales: [.day])
            }
            Section("Goals") {
                if macros.isEmpty {
                    Text("No macros are tracked. Turn some on in Settings.")
                        .foregroundStyle(.secondary)
                }
                ForEach(macros) { macro in
                    MacroProgressRow(
                        title: macro.name,
                        total: entries.reduce(0) { $0 + $1.value(for: macro.id) },
                        goal: macro.dailyGoal,
                        unit: macro.unit,
                        kind: macro.goalKind
                    )
                }
            }
            Section("Food") {
                if entries.isEmpty {
                    Text("Nothing logged yet. Tap + to add food.")
                        .foregroundStyle(.secondary)
                }
                ForEach(entries) { entry in
                    Button {
                        editing = entry
                    } label: {
                        FoodSummaryRow(
                            name: entry.name,
                            detail: entry.servings == 1 ? "" : "× \(entry.servings.formatted())",
                            values: entry.values,
                            macros: macros
                        )
                    }
                    .tint(.primary)
                }
                .onDelete { offsets in
                    offsets.map { entries[$0] }.forEach(context.delete)
                }
            }
        }
        .sheet(item: $editing) { entry in
            NavigationStack {
                EntryFormView(entry: entry, isRoot: true) { editing = nil }
            }
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(PreviewData.makeContainer())
}

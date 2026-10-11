import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Macro.sortOrder) private var macros: [Macro]
    @AppStorage(AppSettings.firstWeekdayKey) private var firstWeekday = Calendar.current.firstWeekday

    @State private var showingNew = false
    @State private var blockedDelete: Macro?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(macros) { macro in
                        NavigationLink {
                            MacroEditorView(macro: macro)
                        } label: {
                            MacroSettingsRow(macro: macro)
                        }
                        .swipeActions(edge: .leading) {
                            Button(macro.isTracked ? "Untrack" : "Track") {
                                macro.isTracked.toggle()
                            }
                            .tint(macro.isTracked ? .gray : .green)
                        }
                    }
                    .onMove(perform: move)
                    .onDelete(perform: delete)
                    Button {
                        showingNew = true
                    } label: {
                        Label("Add Macro", systemImage: "plus")
                    }
                } header: {
                    Text("Macros")
                } footer: {
                    Text("Goals are per day. Week, month and year goals are the daily goal times the number of days. Swipe right to track or untrack.")
                }
                Section("Calendar") {
                    Picker("Week starts on", selection: $firstWeekday) {
                        Text("Sunday").tag(1)
                        Text("Monday").tag(2)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar { EditButton() }
            .sheet(isPresented: $showingNew) {
                NavigationStack { MacroEditorView(macro: nil) }
            }
            .alert(
                "Can't Delete \(blockedDelete?.name ?? "Macro")",
                isPresented: Binding(get: { blockedDelete != nil }, set: { if !$0 { blockedDelete = nil } })
            ) {
                Button("Untrack") { blockedDelete?.isTracked = false }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Logged food has values for this macro. Untrack it to hide it instead.")
            }
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = macros
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, macro) in reordered.enumerated() {
            macro.sortOrder = index
        }
    }

    private func delete(at offsets: IndexSet) {
        for macro in offsets.map({ macros[$0] }) {
            if isReferenced(macro) {
                blockedDelete = macro
            } else {
                context.delete(macro)
            }
        }
    }

    private func isReferenced(_ macro: Macro) -> Bool {
        let entries = (try? context.fetch(FetchDescriptor<FoodEntry>())) ?? []
        return entries.contains { ($0.values[macro.key] ?? 0) != 0 }
    }
}

private struct MacroSettingsRow: View {
    let macro: Macro

    var body: some View {
        HStack {
            Image(systemName: macro.isTracked ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(macro.isTracked ? Color.green : Color.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(macro.name)
                Text(goalText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var goalText: String {
        guard let goal = macro.dailyGoal else { return "No goal · \(macro.unit)" }
        return "\(macro.goalKind.label) \(goal.macroFormatted) \(macro.unit) per day"
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewData.makeContainer())
}

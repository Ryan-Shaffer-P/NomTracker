import SwiftData
import SwiftUI

/// Pick a saved food or quick-add values, then confirm in `EntryFormView`.
struct AddEntryView: View {
    let day: Date

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SavedFood.name) private var foods: [SavedFood]
    @Query(filter: #Predicate<Macro> { $0.isTracked == true }, sort: \Macro.sortOrder)
    private var macros: [Macro]
    @State private var search = ""

    private var filteredFoods: [SavedFood] {
        search.isEmpty ? foods : foods.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        EntryFormView(day: day) { dismiss() }
                    } label: {
                        Label("Quick add", systemImage: "square.and.pencil")
                    }
                }
                Section("Saved foods") {
                    if foods.isEmpty {
                        Text("Foods you save will appear here.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(filteredFoods) { food in
                        NavigationLink {
                            EntryFormView(food: food, day: day) { dismiss() }
                        } label: {
                            FoodSummaryRow(
                                name: food.name,
                                detail: food.servingDescription,
                                values: food.valuesPerServing,
                                macros: macros
                            )
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Search saved foods")
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

/// Edits a new or existing entry as per-serving values times a number of servings.
struct EntryFormView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Macro> { $0.isTracked == true }, sort: \Macro.sortOrder)
    private var macros: [Macro]

    private let entry: FoodEntry?
    private let food: SavedFood?
    private let day: Date
    private let isRoot: Bool
    private let onDone: () -> Void

    @State private var name: String
    @State private var servings: Double
    @State private var perServing: [String: Double]
    @State private var saveAsFood = false

    init(
        entry: FoodEntry? = nil,
        food: SavedFood? = nil,
        day: Date = .now,
        isRoot: Bool = false,
        onDone: @escaping () -> Void
    ) {
        self.entry = entry
        self.food = food
        self.day = day
        self.isRoot = isRoot
        self.onDone = onDone
        if let entry {
            let servings = entry.servings > 0 ? entry.servings : 1
            _name = State(initialValue: entry.name)
            _servings = State(initialValue: servings)
            _perServing = State(initialValue: entry.values.mapValues { $0 / servings })
        } else if let food {
            _name = State(initialValue: food.name)
            _servings = State(initialValue: 1)
            _perServing = State(initialValue: food.valuesPerServing)
        } else {
            _name = State(initialValue: "")
            _servings = State(initialValue: 1)
            _perServing = State(initialValue: [:])
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isQuickAdd: Bool { entry == nil && food == nil }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                Stepper(value: $servings, in: 0.25...100, step: 0.25) {
                    LabeledContent("Servings", value: servings.formatted())
                }
            }
            MacroValuesSection(title: isQuickAdd ? "Amount per serving" : "Per serving", macros: macros, values: $perServing)
            if servings != 1 {
                Section("Total") {
                    ForEach(macros) { macro in
                        LabeledContent(macro.name, value: "\(((perServing[macro.key] ?? 0) * servings).macroFormatted) \(macro.unit)")
                    }
                }
            }
            if isQuickAdd {
                Section {
                    Toggle("Save as food", isOn: $saveAsFood)
                } footer: {
                    Text("Saved foods can be logged again from the Add Food list or the Foods tab.")
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(entry == nil ? "Log Food" : "Edit Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(entry == nil ? "Add" : "Save", action: save)
                    .disabled(saveAsFood && trimmedName.isEmpty)
            }
            if isRoot {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDone)
                }
            }
        }
    }

    private func save() {
        let totals = perServing.mapValues { $0 * servings }
        let finalName = trimmedName.isEmpty ? "Quick add" : trimmedName
        if let entry {
            entry.name = finalName
            entry.servings = servings
            entry.values = totals
        } else {
            context.insert(FoodEntry(timestamp: Self.timestamp(for: day), name: finalName, servings: servings, values: totals))
            if saveAsFood {
                context.insert(SavedFood(name: finalName, valuesPerServing: perServing))
            }
        }
        onDone()
    }

    /// Now when logging for today; midday when logging for another day.
    static func timestamp(for day: Date, calendar: Calendar = .current) -> Date {
        if calendar.isDateInToday(day) { return .now }
        return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
    }
}

#Preview {
    AddEntryView(day: .now)
        .modelContainer(PreviewData.makeContainer())
}

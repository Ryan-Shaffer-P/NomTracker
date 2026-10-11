import SwiftData
import SwiftUI

/// Create or edit a saved food. Edits don't change entries already logged.
struct FoodEditorView: View {
    let food: SavedFood?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Macro> { $0.isTracked == true }, sort: \Macro.sortOrder)
    private var macros: [Macro]

    @State private var name: String
    @State private var servingDescription: String
    @State private var values: [String: Double]

    init(food: SavedFood?) {
        self.food = food
        _name = State(initialValue: food?.name ?? "")
        _servingDescription = State(initialValue: food?.servingDescription ?? "")
        _values = State(initialValue: food?.valuesPerServing ?? [:])
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                TextField("Serving size (e.g. 1 cup)", text: $servingDescription)
            }
            MacroValuesSection(title: "Per serving", macros: macros, values: $values)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(food == nil ? "New Food" : "Edit Food")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(trimmedName.isEmpty)
            }
        }
    }

    private func save() {
        if let food {
            food.name = trimmedName
            food.servingDescription = servingDescription
            food.valuesPerServing = values
        } else {
            context.insert(SavedFood(name: trimmedName, servingDescription: servingDescription, valuesPerServing: values))
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        FoodEditorView(food: nil)
    }
    .modelContainer(PreviewData.makeContainer())
}

import SwiftData
import SwiftUI

/// Create or edit a macro: name, unit, daily goal and whether it's a minimum or a maximum.
struct MacroEditorView: View {
    let macro: Macro?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Macro.sortOrder) private var allMacros: [Macro]

    @State private var name: String
    @State private var unit: String
    @State private var dailyGoal: Double?
    @State private var goalKind: GoalKind
    @State private var isTracked: Bool

    init(macro: Macro?) {
        self.macro = macro
        _name = State(initialValue: macro?.name ?? "")
        _unit = State(initialValue: macro?.unit ?? "g")
        _dailyGoal = State(initialValue: macro?.dailyGoal)
        _goalKind = State(initialValue: macro?.goalKind ?? .atLeast)
        _isTracked = State(initialValue: macro?.isTracked ?? true)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            Section {
                TextField("Name (e.g. Potassium)", text: $name)
                TextField("Unit (e.g. g, mg, kcal)", text: $unit)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Toggle("Tracked", isOn: $isTracked)
            }
            Section {
                Picker("Goal type", selection: $goalKind) {
                    ForEach(GoalKind.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                LabeledContent("Daily goal") {
                    HStack(spacing: 6) {
                        TextField("None", value: $dailyGoal, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(unit).foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Goal")
            } footer: {
                Text(goalKind == .atLeast
                     ? "Reaching the goal counts as met. Use for things like protein and fiber."
                     : "Staying at or under the goal counts as met. Use for things like calories and sugar.")
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(macro == nil ? "New Macro" : "Edit Macro")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if macro == nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(trimmedName.isEmpty)
            }
        }
    }

    private func save() {
        let goal = dailyGoal.flatMap { $0 > 0 ? $0 : nil }
        let unit = unit.trimmingCharacters(in: .whitespaces)
        if let macro {
            macro.name = trimmedName
            macro.unit = unit
            macro.dailyGoal = goal
            macro.goalKind = goalKind
            macro.isTracked = isTracked
        } else {
            let nextOrder = (allMacros.map(\.sortOrder).max() ?? -1) + 1
            context.insert(Macro(name: trimmedName, unit: unit, dailyGoal: goal, goalKind: goalKind, isTracked: isTracked, sortOrder: nextOrder))
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        MacroEditorView(macro: nil)
    }
    .modelContainer(PreviewData.makeContainer())
}

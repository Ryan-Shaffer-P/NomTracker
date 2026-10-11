import SwiftData
import SwiftUI

/// Logs an amount of one macro without describing a food, e.g. "+25 g protein".
struct QuickMacroView: View {
    let day: Date
    let onDone: () -> Void

    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Macro> { $0.isTracked == true }, sort: \Macro.sortOrder)
    private var macros: [Macro]

    @State private var selectedID: UUID?
    @State private var amountText = ""
    @FocusState private var amountFocused: Bool

    /// Parsed live from the text so Add enables as you type.
    private var amount: Double? {
        try? Double(amountText, format: .number)
    }

    private var selected: Macro? {
        macros.first { $0.id == selectedID } ?? macros.first
    }

    var body: some View {
        Form {
            if macros.isEmpty {
                Text("No macros are tracked. Turn some on in Settings.")
                    .foregroundStyle(.secondary)
            } else {
                Section {
                    Picker("Macro", selection: Binding(get: { selected?.id }, set: { selectedID = $0 })) {
                        ForEach(macros) { Text($0.name).tag(Optional($0.id)) }
                    }
                    LabeledContent("Amount") {
                        HStack(spacing: 6) {
                            TextField("0", text: $amountText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($amountFocused)
                            Text(selected?.unit ?? "")
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Adds this amount to the day's total without logging a food.")
                }
            }
        }
        .navigationTitle("Quick Macro")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { amountFocused = true }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add", action: save)
                    .disabled(selected == nil || (amount ?? 0) <= 0)
            }
        }
    }

    private func save() {
        guard let macro = selected, let amount, amount > 0 else { return }
        context.insert(FoodEntry(
            timestamp: EntryFormView.timestamp(for: day),
            name: macro.name,
            values: [macro.key: amount]
        ))
        onDone()
    }
}

#Preview {
    NavigationStack {
        QuickMacroView(day: .now) {}
    }
    .modelContainer(PreviewData.makeContainer())
}

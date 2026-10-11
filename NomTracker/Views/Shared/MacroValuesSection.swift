import SwiftUI

/// Number fields for each macro, editing a `[Macro.key: amount]` dictionary.
struct MacroValuesSection: View {
    let title: String
    let macros: [Macro]
    @Binding var values: [String: Double]

    var body: some View {
        Section(title) {
            if macros.isEmpty {
                Text("No macros are tracked. Turn some on in Settings.")
                    .foregroundStyle(.secondary)
            }
            ForEach(macros) { macro in
                LabeledContent(macro.name) {
                    HStack(spacing: 6) {
                        TextField("0", value: binding(for: macro), format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(macro.unit)
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 32, alignment: .leading)
                    }
                }
            }
        }
    }

    private func binding(for macro: Macro) -> Binding<Double?> {
        Binding(
            get: { values[macro.key] },
            set: { values[macro.key] = $0 }
        )
    }
}

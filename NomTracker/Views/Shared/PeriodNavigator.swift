import SwiftUI

/// Scale picker plus previous/next buttons. Tapping the label jumps back to the current period.
struct PeriodNavigator: View {
    @Binding var period: Period
    let calendar: Calendar
    var scales: [PeriodScale] = PeriodScale.allCases

    var body: some View {
        VStack(spacing: 10) {
            if scales.count > 1 {
                Picker("Scale", selection: $period.scale) {
                    ForEach(scales) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            HStack {
                Button {
                    period = period.previous(in: calendar)
                } label: {
                    Image(systemName: "chevron.left")
                        .accessibilityLabel("Previous")
                }
                Spacer()
                Button {
                    period.anchor = .now
                } label: {
                    Text(period.label(in: calendar))
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                Spacer()
                Button {
                    period = period.next(in: calendar)
                } label: {
                    Image(systemName: "chevron.right")
                        .accessibilityLabel("Next")
                }
                .disabled(isCurrent)
            }
            .buttonStyle(.borderless)
            .imageScale(.large)
        }
    }

    private var isCurrent: Bool {
        period.contains(.now, in: calendar)
    }
}

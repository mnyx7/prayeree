import SwiftUI

struct DatePickerSheet: View {
    @State private var selectedDate: Date
    let onDateSelected: (Date) -> Void
    let onDismiss: () -> Void

    init(initialDate: Date, onDateSelected: @escaping (Date) -> Void, onDismiss: @escaping () -> Void) {
        _selectedDate = State(initialValue: initialDate)
        self.onDateSelected = onDateSelected
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            DatePicker(String(localized: LocalizedKey.PrayerTimes.selectDate), selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding()
                .navigationTitle(Text(LocalizedKey.PrayerTimes.selectDate))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: LocalizedKey.Common.cancel), action: onDismiss)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(String(localized: LocalizedKey.Common.done)) { onDateSelected(selectedDate) }
                    }
                }
        }
    }
}

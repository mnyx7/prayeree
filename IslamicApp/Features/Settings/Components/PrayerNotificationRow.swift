import SwiftUI

struct PrayerNotificationRow: View {
    let prayer: PrayerName
    let isEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
        Toggle(String(localized: LocalizedKey.PrayerName.displayName(for: prayer)), isOn: Binding(get: { isEnabled }, set: { _ in onToggle() }))
    }
}

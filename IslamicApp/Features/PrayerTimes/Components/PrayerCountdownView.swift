import SwiftUI

struct PrayerCountdownView: View {
    let nextPrayer: PrayerTime?
    let remaining: TimeInterval

    var body: some View {
        if let nextPrayer {
            let prayerDisplayName = String(localized: LocalizedKey.PrayerName.displayName(for: nextPrayer.name))
            Text(LocalizedKey.PrayerTimes.nextPrayerCountdown(prayer: prayerDisplayName, countdown: TimeFormatter.countdown(from: remaining)))
                .font(.title3.weight(.semibold))
                // The visible "01:24" digit format isn't screen-reader-friendly,
                // so VoiceOver gets a separate, correctly-pluralized phrase instead.
                .accessibilityLabel(
                    LocalizationManager.countdownAccessibilityLabel(prayerName: prayerDisplayName, remainingSeconds: remaining)
                )
        } else {
            Text(LocalizedKey.PrayerTimes.allPrayersComplete)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)
        }
    }
}

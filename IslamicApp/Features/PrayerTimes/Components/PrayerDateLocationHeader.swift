import SwiftUI

struct PrayerDateLocationHeader: View {
    let cityName: String
    let gregorianDate: Date
    let hijriDate: HijriDate?
    let onDateTapped: () -> Void
    let onLocationTapped: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            Button(action: onLocationTapped) {
                Label(cityName, systemImage: "mappin.and.ellipse")
                    .font(.subheadline.weight(.medium))
            }

            Spacer()

            Button(action: onDateTapped) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(DateFormatterFactory.gregorianMediumDate().string(from: gregorianDate))
                        .font(.subheadline)
                    if let hijriDate {
                        Text(hijriDisplayText(hijriDate))
                            .font(.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func hijriDisplayText(_ date: HijriDate) -> String {
        let monthName = String(localized: LocalizedKey.HijriMonthName.displayName(for: date.month))
        return String(localized: LocalizedKey.PrayerTimes.hijriDateLabel(day: date.day, month: monthName, year: date.year))
    }
}

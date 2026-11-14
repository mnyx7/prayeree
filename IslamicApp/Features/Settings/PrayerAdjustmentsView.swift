//
//  PrayerAdjustmentsView.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

struct PrayerAdjustmentsView: View {
    let store: SettingsStore

    var body: some View {
        Form {
            Section {
                ForEach(PrayerName.allCases) { prayer in
                    Stepper(
                        stepperLabel(for: prayer),
                        value: Binding(
                            get: { store.prayerAdjustment.minutes(for: prayer) },
                            set: { store.send(.prayerAdjustmentChanged(prayer, $0)) }
                        ),
                        in: -30...30
                    )
                }
            } footer: {
                Text(LocalizedKey.Settings.adjustmentsFooter)
            }
        }
        .navigationTitle(Text(LocalizedKey.Settings.manualAdjustments))
    }

    private func stepperLabel(for prayer: PrayerName) -> String {
        let prayerName = String(localized: LocalizedKey.PrayerName.displayName(for: prayer))
        let minutesLabel = String(localized: LocalizedKey.Settings.minutesOffset(formattedMinutes(store.prayerAdjustment.minutes(for: prayer))))
        return "\(prayerName): \(minutesLabel)"
    }

    private func formattedMinutes(_ minutes: Int) -> String {
        if minutes == 0 { return "0" }
        return minutes > 0 ? "+\(minutes)" : "\(minutes)"
    }
}

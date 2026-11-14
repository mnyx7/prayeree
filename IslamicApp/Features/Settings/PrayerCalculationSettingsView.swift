//
//  PrayerCalculationSettingsView.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

struct PrayerCalculationSettingsView: View {
    let store: SettingsStore

    var body: some View {
        Form {
            Section {
                Picker(
                    String(localized: LocalizedKey.Settings.calculationMethodSection),
                    selection: Binding(get: { store.calculationMethod }, set: { store.send(.calculationMethodChanged($0)) })
                ) {
                    ForEach(PrayerCalculationMethod.allCases) { method in
                        Text(LocalizedKey.Settings.calculationMethodName(method)).tag(method)
                    }
                }
                .pickerStyle(.navigationLink)
            } header: {
                Text(LocalizedKey.Settings.calculationMethodSection)
            }

            Section {
                Picker(
                    String(localized: LocalizedKey.Settings.asrMadhabSection),
                    selection: Binding(get: { store.madhab }, set: { store.send(.madhabChanged($0)) })
                ) {
                    Text(LocalizedKey.Settings.madhabStandard).tag(MadhabOption.shafiMalikiHanbali)
                    Text(LocalizedKey.Settings.madhabHanafi).tag(MadhabOption.hanafi)
                }
                .pickerStyle(.segmented)
            } header: {
                Text(LocalizedKey.Settings.asrMadhabSection)
            }
        }
        .navigationTitle(Text(LocalizedKey.Settings.prayerSettingsSection))
    }
}

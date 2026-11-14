//
//  AppearancePicker.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

struct AppearancePicker: View {
    let selection: AppAppearanceMode
    let onChange: (AppAppearanceMode) -> Void

    var body: some View {
        Picker(String(localized: LocalizedKey.Settings.appearanceSection), selection: Binding(get: { selection }, set: onChange)) {
            Text(LocalizedKey.Settings.appearanceSystem).tag(AppAppearanceMode.system)
            Text(LocalizedKey.Settings.appearanceLight).tag(AppAppearanceMode.light)
            Text(LocalizedKey.Settings.appearanceDark).tag(AppAppearanceMode.dark)
        }
        .pickerStyle(.segmented)
    }
}

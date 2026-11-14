//
//  AboutUsView.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

struct AboutUsView: View {
    let appVersion: String

    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppColor.accent)
                    Text(LocalizedKey.Settings.aboutUsAppName)
                        .font(.title2.weight(.semibold))
                    Text(LocalizedKey.Settings.versionLabel(appVersion))
                        .font(.subheadline)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .listRowBackground(Color.clear)

            Section {
                Text(LocalizedKey.Settings.aboutUsBody)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
            } header: {
                Text(LocalizedKey.Settings.aboutSection)
            }
        }
        .navigationTitle(Text(LocalizedKey.Settings.aboutUs))
    }
}

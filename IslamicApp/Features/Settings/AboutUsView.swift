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
                    Image("BrandLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .accessibilityHidden(true)
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
                Link("Quran data provided by Quran.Foundation.", destination: URL(string: "https://quran.foundation")!)
                Text("Translation credits appear with Quran content. Text and translations belong to their respective rights holders.")
                    .font(.footnote)
            } header: {
                Text(LocalizedKey.Settings.aboutSection)
            }
        }
        .navigationTitle(Text(LocalizedKey.Settings.aboutUs))
    }
}

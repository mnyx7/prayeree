//
//  SettingsNavigationRow.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

struct SettingsNavigationRow: View {
    let title: LocalizedStringResource
    let systemImage: String
    let value: String?

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            if let value {
                Text(value)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppColor.textSecondary.opacity(0.6))
        }
        .contentShape(Rectangle())
    }
}

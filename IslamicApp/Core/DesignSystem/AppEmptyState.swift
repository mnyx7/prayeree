//
//  AppEmptyState.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

struct AppEmptyState: View {
    let systemImage: String
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(systemImage: String, title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.systemImage = systemImage
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: systemImage)
                .font(.system(size: 32))
                .foregroundStyle(AppColor.textSecondary)
            Text(title)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.appSecondary)
                    .frame(maxWidth: 220)
            }
        }
        .padding(.top, AppSpacing.xLarge)
        .padding(.horizontal, AppSpacing.xLarge)
    }
}

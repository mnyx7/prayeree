//
//  AppRow.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

struct AppRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .appRowStyle()
    }
}

extension View {
    func appRowStyle() -> some View {
        self
            .padding(.vertical, AppSpacing.xSmall)
            .padding(.horizontal, AppSpacing.medium)
    }
}

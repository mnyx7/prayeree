//
//  AppShadow.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

// A single restrained elevation treatment — Phase 11 explicitly warns against
// heavy shadows, so this is intentionally the only shadow style in the app.
private struct AppShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func appShadow() -> some View {
        modifier(AppShadowModifier())
    }
}

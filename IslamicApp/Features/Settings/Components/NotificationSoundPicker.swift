//
//  NotificationSoundPicker.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

// V1 offers only "Default" — a custom UNNotificationSound requires a bundled
// .caf/.aiff/.wav asset (≤30s), and no such asset ships in V1. The row and
// preview action exist so adding real sound options later only means adding
// bundled files and rows here, not new architecture (see Phase 10 notes).
struct NotificationSoundPicker: View {
    let onPreviewTapped: () -> Void

    var body: some View {
        HStack {
            Label(LocalizedKey.Settings.defaultSound, systemImage: "checkmark.circle.fill")
                .foregroundStyle(AppColor.accent)
            Spacer()
            Button(String(localized: LocalizedKey.Settings.preview), action: onPreviewTapped)
                .buttonStyle(.bordered)
        }
    }
}

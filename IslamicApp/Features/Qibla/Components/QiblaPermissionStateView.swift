//
//  QiblaPermissionStateView.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI
import CoreLocation

struct QiblaPermissionStateView: View {
    let authorizationStatus: CLAuthorizationStatus
    let errorMessage: String?
    let onRequestPermission: () -> Void
    let onRetry: () -> Void

    var body: some View {
        AppEmptyState(
            systemImage: iconName,
            title: message,
            actionTitle: actionTitle,
            action: action
        )
    }

    private var iconName: String {
        switch authorizationStatus {
        case .denied, .restricted: return "location.slash"
        default: return "location.circle"
        }
    }

    private var message: String {
        if let errorMessage { return errorMessage }
        switch authorizationStatus {
        case .notDetermined:
            return String(localized: LocalizedKey.Qibla.permissionPromptNotDetermined)
        case .denied:
            return String(localized: LocalizedKey.Qibla.permissionPromptDenied)
        case .restricted:
            return String(localized: LocalizedKey.Qibla.permissionPromptRestricted)
        default:
            return String(localized: LocalizedKey.Qibla.permissionPromptUnknown)
        }
    }

    private var actionTitle: String {
        authorizationStatus == .notDetermined
            ? String(localized: LocalizedKey.Qibla.allowLocationAccess)
            : String(localized: LocalizedKey.Common.tryAgain)
    }

    private var action: () -> Void {
        authorizationStatus == .notDetermined ? onRequestPermission : onRetry
    }
}

//
//  QiblaView.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

struct QiblaView: View {
    let store: QiblaStore

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xLarge) {
                switch content {
                case .compass:
                    Spacer(minLength: 8)
                    QiblaCompassView(
                        heading: store.state.heading,
                        bearing: store.state.bearing,
                        relativeAngle: store.state.relativeAngle
                    )
                    QiblaDegreeCard(bearing: store.state.bearing, heading: store.state.heading)
                    if store.state.isCalibrationVisible {
                        QiblaCalibrationHint()
                    }
                    Spacer()

                case .loading:
                    Spacer()
                    ProgressView()
                    Spacer()

                case .permissionOrError:
                    QiblaPermissionStateView(
                        authorizationStatus: store.state.authorizationStatus,
                        errorMessage: store.state.errorMessage,
                        onRequestPermission: { store.send(.locationPermissionRequested) },
                        onRetry: { store.send(.retryTapped) }
                    )
                    Spacer()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.backgroundPrimary)
            .navigationTitle(Text(LocalizedKey.Qibla.tabTitle))
            .task { store.send(.screenAppeared) }
            .onDisappear { store.send(.screenDisappeared) }
        }
    }

    private enum ContentKind {
        case compass, loading, permissionOrError
    }

    private var content: ContentKind {
        if store.state.bearing != nil {
            return .compass
        }
        switch store.state.authorizationStatus {
        case .denied, .restricted, .notDetermined:
            return .permissionOrError
        default:
            break
        }
        if store.state.errorMessage != nil {
            return .permissionOrError
        }
        return .loading
    }
}

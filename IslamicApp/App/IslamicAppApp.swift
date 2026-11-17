//
//  IslamicAppApp.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

@main
struct IslamicAppApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var environment: AppEnvironment
    @State private var appStore: AppStore
    @State private var showsSplash = true
    @AppStorage(LocalizationManager.languagePreferenceKey) private var appLanguage = ""

    init() {
        let environment = AppEnvironment.live()
        _environment = State(initialValue: environment)
        _appStore = State(initialValue: AppStore(environment: environment))
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootTabView(appStore: appStore, environment: environment)
                    .accessibilityHidden(showsSplash)
                if showsSplash {
                    BrandSplashView {
                        withAnimation(.easeOut(duration: 0.3)) { showsSplash = false }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
                .environment(\.locale, LocalizationManager.locale)
                .environment(\.layoutDirection, LocalizationManager.isRightToLeft ? .rightToLeft : .leftToRight)
                .onChange(of: appLanguage) { _, _ in
                    appStore.send(.notificationPreferencesChanged)
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { appStore.send(.appLaunched) }
                    else { environment.widgetPublisher?.flushReadingReload() }
                }
                .task {
                    appStore.send(.appLaunched)
                }
        }
    }
}


// A brief foreground introduction; the system launch screen remains static.
private struct BrandSplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false
    let completion: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.97483, green: 0.98396, blue: 0.97506).ignoresSafeArea()
            VStack(spacing: 22) {
                Image("BrandLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .scaleEffect(revealed || reduceMotion ? 1 : 0.86)
                    .rotationEffect(.degrees(revealed || reduceMotion ? 0 : -8))
                    .accessibilityHidden(true)
                Text("Islamic Companion")
                    .font(.system(.largeTitle, design: .serif, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(red: 0.08, green: 0.39, blue: 0.29))
                    .offset(y: revealed || reduceMotion ? 0 : 10)
            }
            .padding(24)
            .opacity(revealed ? 1 : 0)
        }
        .task {
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.7, dampingFraction: 0.8)) {
                revealed = true
            }
            do { try await Task.sleep(for: .seconds(reduceMotion ? 0.6 : 1.4)) }
            catch { return }
            completion()
        }
    }
}

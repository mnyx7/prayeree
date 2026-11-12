import SwiftUI

struct AppErrorState: View {
    let message: String
    let retryTitle: String
    let onRetry: () -> Void

    init(message: String, retryTitle: String = "Try Again", onRetry: @escaping () -> Void) {
        self.message = message
        self.retryTitle = retryTitle
        self.onRetry = onRetry
    }

    var body: some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(AppColor.warning)
            Text(message)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
            Button(retryTitle, action: onRetry)
                .buttonStyle(.appPrimary)
                .frame(maxWidth: 220)
        }
        .padding(.top, AppSpacing.xLarge)
        .padding(.horizontal, AppSpacing.xLarge)
    }
}

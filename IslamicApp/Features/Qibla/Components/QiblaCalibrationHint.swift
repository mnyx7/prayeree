import SwiftUI

struct QiblaCalibrationHint: View {
    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.xSmall) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundStyle(AppColor.textPrimary)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(LocalizedKey.Qibla.calibrationTitle)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Text(LocalizedKey.Qibla.calibrationSubtitle)
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .padding(AppSpacing.small)
        .background(AppColor.warning, in: RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
    }
}

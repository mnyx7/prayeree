import SwiftUI

struct QiblaDegreeCard: View {
    let bearing: QiblaDirection?
    let heading: CompassHeading?

    var body: some View {
        VStack(spacing: AppSpacing.xSmall) {
            if let bearing {
                Text("\(Int(bearing.bearingDegrees.rounded()))°")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.textPrimary)
                Text(directionLabel(for: bearing.bearingDegrees))
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColor.textSecondary)
            } else {
                Text("--°")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.textSecondary)
            }

            if bearing != nil, heading == nil {
                Text(LocalizedKey.Qibla.liveCompassUnavailable)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .appCardStyle()
    }

    private func directionLabel(for degrees: Double) -> LocalizedStringResource {
        let directions = [
            LocalizedKey.Qibla.directionNorth, LocalizedKey.Qibla.directionNNE,
            LocalizedKey.Qibla.directionNE, LocalizedKey.Qibla.directionENE,
            LocalizedKey.Qibla.directionEast, LocalizedKey.Qibla.directionESE,
            LocalizedKey.Qibla.directionSE, LocalizedKey.Qibla.directionSSE,
            LocalizedKey.Qibla.directionSouth, LocalizedKey.Qibla.directionSSW,
            LocalizedKey.Qibla.directionSW, LocalizedKey.Qibla.directionWSW,
            LocalizedKey.Qibla.directionWest, LocalizedKey.Qibla.directionWNW,
            LocalizedKey.Qibla.directionNW, LocalizedKey.Qibla.directionNNW
        ]
        let index = Int((degrees / 22.5).rounded()) % directions.count
        return directions[index]
    }
}

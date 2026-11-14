//
//  QiblaCompassView.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

struct QiblaCompassView: View {
    let heading: CompassHeading?
    let bearing: QiblaDirection?
    let relativeAngle: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColor.divider, lineWidth: 2)

            ForEach(0..<4, id: \.self) { tick in
                Rectangle()
                    .fill(AppColor.textSecondary)
                    .frame(width: 2, height: 10)
                    .offset(y: -140)
                    .rotationEffect(.degrees(Double(tick) * 90))
            }

            VStack {
                Text(LocalizedKey.Qibla.kaaba)
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.top, AppSpacing.large)
                Spacer()
            }

            // Points toward the Qibla: 0° means the device's forward axis is
            // already aligned with it, so the arrow rotates by exactly
            // `relativeAngle` from straight-up.
            Image(systemName: "location.north.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppColor.accent)
                .rotationEffect(.degrees(relativeAngle))
                .animation(.easeOut(duration: 0.2), value: relativeAngle)
        }
        .frame(width: 280, height: 280)
        .opacity(bearing == nil ? 0.3 : 1)
    }
}

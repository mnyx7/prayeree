//
//  TimeFormatter.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

enum TimeFormatter {
    /// Formats a countdown interval as "HH:mm", e.g. "01:24". Negative or
    /// sub-minute intervals clamp to "00:00" rather than showing a negative time.
    static func countdown(from interval: TimeInterval) -> String {
        let clamped = max(0, interval)
        let totalSeconds = Int(clamped.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

//
//  Calendar+Hijri.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

extension Calendar {
    static var islamicUmmAlQura: Calendar {
        Calendar(identifier: .islamicUmmAlQura)
    }
}

extension Date {
    // Local fallback for computing the Hijri date without a network call;
    // Phase 4's mapper may prefer AlAdhan's own Hijri value when available.
    func hijriDate(using calendar: Calendar = .islamicUmmAlQura) -> HijriDate {
        let components = calendar.dateComponents([.day, .month, .year], from: self)
        let day = components.day ?? 1
        let year = components.year ?? 0
        let month = HijriMonth(rawValue: components.month ?? 1) ?? .muharram
        return HijriDate(day: day, month: month, year: year)
    }
}

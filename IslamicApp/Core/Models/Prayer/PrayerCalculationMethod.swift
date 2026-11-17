//
//  PrayerCalculationMethod.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

/// Existing raw values are persisted preferences and must remain stable.
/// 1000 identifies the separate Minber/QMİ timetable provider, not an AlAdhan method.
enum PrayerCalculationMethod: Int, Codable, CaseIterable, Identifiable, Sendable {
    case karachi = 1
    case northAmerica = 2
    case muslimWorldLeague = 3
    case ummAlQura = 4
    case egyptianGeneralAuthority = 5
    case tehran = 7
    case dubai = 8
    case kuwait = 9
    case qatar = 10
    case singapore = 11
    case turkey = 13
    case moonsightingCommittee = 15
    case qmiMinber = 1000

    // Keep persisted raw values stable. AlAdhan's Dubai preset is 16; 8 is Gulf Region.
    var aladhanID: Int { self == .dubai ? 16 : rawValue }
    var id: Int { rawValue }
}

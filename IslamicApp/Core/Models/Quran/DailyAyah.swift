//
//  DailyAyah.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import Foundation

struct DailyAyah: Codable, Equatable, Sendable {
    let date: Date
    let ayah: Ayah
}

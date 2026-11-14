//
//  Collection+Safe.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

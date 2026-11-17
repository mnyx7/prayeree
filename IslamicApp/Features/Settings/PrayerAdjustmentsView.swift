//
//  PrayerAdjustmentsView.swift
//  Islamic Companion
//
//  Created by Minaya on 14/11/2026.
//

import SwiftUI

struct PrayerAdjustmentsView: View {
    let store: SettingsStore
    @State private var editingPrayer: PrayerName?

    var body: some View {
        Form {
            Section {
                ForEach(PrayerName.allCases) { prayer in
                    HStack {
                        Text(LocalizedKey.PrayerName.displayName(for: prayer))
                        Spacer()
                        adjustmentButton("minus", prayer: prayer, change: -1)
                        Button {
                            editingPrayer = prayer
                        } label: {
                            Text(LocalizedKey.Settings.minutesOffset(formattedMinutes(store.prayerAdjustment.minutes(for: prayer))))
                                .monospacedDigit()
                                .frame(minWidth: 64, minHeight: 44)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(Text(LocalizedKey.PrayerName.displayName(for: prayer)))
                        .accessibilityValue(formattedMinutes(store.prayerAdjustment.minutes(for: prayer)))
                        .accessibilityHint(Text("Tap to enter minutes"))
                        adjustmentButton("plus", prayer: prayer, change: 1)
                    }
                }
            } footer: {
                Text("Tap a number to enter minutes, or use minus and plus for one-minute changes. Adjust up to 60 minutes earlier or later.")
            }
        }
        .navigationTitle(Text(LocalizedKey.Settings.manualAdjustments))
        .sheet(item: $editingPrayer) { prayer in
            PrayerAdjustmentEditor(prayer: prayer, minutes: store.prayerAdjustment.minutes(for: prayer)) { minutes in
                store.send(.prayerAdjustmentChanged(prayer, minutes))
            }
        }
    }

    private func adjustmentButton(_ symbol: String, prayer: PrayerName, change: Int) -> some View {
        let minutes = store.prayerAdjustment.minutes(for: prayer)
        return Button {
            store.send(.prayerAdjustmentChanged(prayer, min(60, max(-60, minutes + change))))
        } label: {
            Image(systemName: symbol)
                .frame(width: 44, height: 44)
                .background(.quaternary, in: Circle())
        }
        .buttonStyle(.borderless)
        .disabled(change < 0 ? minutes <= -60 : minutes >= 60)
        .accessibilityLabel(change < 0 ? Text("One minute earlier") : Text("One minute later"))
    }

    private func formattedMinutes(_ minutes: Int) -> String {
        minutes > 0 ? "+\(minutes)" : "\(minutes)"
    }
}

private struct PrayerAdjustmentEditor: View {
    let prayer: PrayerName
    let onSave: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    @State private var input: String
    @State private var isEarlier: Bool

    init(prayer: PrayerName, minutes: Int, onSave: @escaping (Int) -> Void) {
        self.prayer = prayer
        self.onSave = onSave
        _input = State(initialValue: String(minutes == 0 ? 5 : min(60, abs(minutes))))
        _isEarlier = State(initialValue: minutes < 0)
    }

    private var validMinutes: Int? {
        guard let minutes = Int(input), (0...60).contains(minutes) else { return nil }
        return minutes
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Direction", selection: $isEarlier) {
                        Text("Earlier").tag(true)
                        Text("Later").tag(false)
                    }
                    .pickerStyle(.segmented)
                    HStack {
                        Text("Minutes")
                        Spacer()
                        TextField("5", text: $input)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($isFocused)
                            .frame(minWidth: 64, minHeight: 44)
                            .accessibilityLabel(Text("Minutes"))
                    }
                } footer: {
                    Text("Enter 0–60 minutes. Use 0 to remove the adjustment.")
                }
                if validMinutes == nil {
                    Text("Enter a number from 0 to 60.")
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(Text(LocalizedKey.PrayerName.displayName(for: prayer)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let minutes = validMinutes else { return }
                        onSave(isEarlier ? -minutes : minutes)
                        dismiss()
                    }
                    .disabled(validMinutes == nil)
                }
            }
            .onAppear { isFocused = true }
        }
    }
}

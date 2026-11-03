//
//  ProgressComputable.swift
//  MillariumCore
//

import Foundation

/// Ein Knoten, dessen Fortschritt berechnet werden kann.
///
/// Wird sowohl von `Millarium` (DTO) als auch von den Domain-Structs in
/// `BasiliskCore` implementiert. Progress ist `Double`, damit SwiftUI-APIs
/// (`ProgressView`, `GeometryReader`, Animationen) ohne Casts funktionieren.
public protocol ProgressComputable {

    /// Anzahl der Kinder.
    var childCount: Int { get }

    /// Fortschritt der Kinder (jeweils 0.0 bis 1.0).
    /// Wenn der Knoten ein Blatt ist, wird dieser Wert ignoriert.
    var childProgresses: [Double] { get }

    /// Nur relevant, wenn dieser Knoten KEINE Kinder hat.
    var isCompleted: Bool { get }
}

public extension ProgressComputable {

    /// Ist dieser Knoten ein Blatt (keine Kinder)?
    var isLeaf: Bool {
        childCount == 0
    }

    /// Berechneter Fortschritt zwischen 0.0 und 1.0.
    ///
    /// - Wenn der Knoten Kinder hat: Durchschnitt der Kinder-Fortschritte
    /// - Wenn der Knoten ein Blatt ist: isCompleted ? 1.0 : 0.0
    var progress: Double {
        if childCount == 0 {
            return isCompleted ? 1.0 : 0.0
        }
        guard !childProgresses.isEmpty else { return 0.0 }
        let sum = childProgresses.reduce(0, +)
        return sum / Double(childProgresses.count)
    }

    /// Fortschritt als gerundeter Prozentwert (0 bis 100).
    var progressPercent: Int {
        Int((progress * 100).rounded())
    }
}

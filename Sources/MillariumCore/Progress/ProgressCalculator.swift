//
//  ProgressCalculator.swift
//  MillariumCore
//
//  Created by Ferdinand Reichart on 21.09.2026.
//


//
//  ProgressCalculator.swift
//  MillariumCore
//
//  Created by Ferdinand Reichart on 21.09.2026.
//

import Foundation

/// Zentrale Fortschrittsberechnung.
///
/// Funktioniert mit jedem Typ, der `ProgressComputable` implementiert
/// (sowohl `Millarium` als auch Core Data Entities).
public enum ProgressCalculator {
    
    /// Berechnet den Fortschritt eines beliebigen `ProgressComputable`.
    public static func calculate(for node: some ProgressComputable) -> Double {
        node.progress
    }   
    
    /// Rundet einen Fortschrittswert auf eine Anzeige-Ganzzahl in Prozent.
    public static func percent(_ progress: Float) -> Int {
        Int((progress * 100).rounded())
    }
    
    /// Berechnet den Fortschritt nur anhand von Zahlen (für Unit-Tests).
    public static func calculate(
        childCount: Int,
        completedChildCount: Int,
        isLeaf: Bool,
        isCompleted: Bool
    ) -> Float {
        if isLeaf {
            return isCompleted ? 1.0 : 0.0
        }
        guard childCount > 0 else { return 0.0 }
        return Float(completedChildCount) / Float(childCount)
    }
}

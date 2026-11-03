//
//  MillariumDegree.swift
//  MyTool
//
//  Created by Ferdinand Reichart on 20.09.2026.
//


import Foundation

/// Die sechs Grade des Millarium-Systems
public enum MillariumDegree: Int, Codable, CaseIterable, Comparable {
    case course = 1
    case chapter = 2
    case part = 3          // optional
    case subchapter = 4
    case step = 5
    case substep = 6       // optional
    
    public static func < (lhs: MillariumDegree, rhs: MillariumDegree) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    public var displayName: String {
        switch self {
        case .course: return "Kurs"
        case .chapter: return "Kapitel"
        case .part: return "Teil"
        case .subchapter: return "Unterkapitel"
        case .step: return "Schritt"
        case .substep: return "Unterschritt"
        }
    }
    
    /// Der nächste tiefere Grad (n+1) oder nil, wenn ganz unten
    public var deeper: MillariumDegree? {
        MillariumDegree(rawValue: rawValue + 1)
    }
    
    /// Der nächsthöhere Grad (n-1) oder nil, wenn ganz oben
    public var shallower: MillariumDegree? {
        MillariumDegree(rawValue: rawValue - 1)
    }
}
//
//  Millarium.swift
//  MillariumCore
//
//  Created by Ferdinand Reichart on 21.09.2026.
//


//
//  Millarium.swift
//  MillariumCore
//
//  Created by Ferdinand Reichart on 20.09.2026.
//

import Foundation

/// Ein Millarium ist ein Knoten im Baum des Syllabus.
/// Es hat einen Grad (1-6), einen Namen, Notizen und optional Kinder.
///
/// **Hinweis:** Dies ist ein DTO (Data Transfer Object). In der Basilisk-App
/// wird derselbe Baum auch durch Core Data Entities dargestellt. Der DTO
/// wird nur für Parser-Ergebnisse und den Import/Export genutzt.
public struct Millarium: Identifiable, Equatable, ProgressComputable {
    public let id: UUID
    public var degree: MillariumDegree
    public var title: String
    public var notes: String?
    public var courseNumber: String?
    
    /// Nur relevant, wenn dieser Knoten KEINE Kinder hat.
    /// Wenn er Kinder hat, wird `isCompleted` ignoriert.
    public var isCompleted: Bool
    
    /// Datei-Verlinkungen. Nur ab Subchapter (4) erlaubt.
    public var fileLinks: [FileLink]
    
    /// Ordner-URL, falls dieser Knoten mit einem Ordner im Dateisystem verknüpft ist.
    public var folderURL: URL?
    
    /// Kinder, sortiert nach `order`
    public var children: [Millarium]
    
    /// Optional für Erinnerungs-Synchronisation
    public var reminderIdentifier: String?
    
    public init(
        id: UUID = UUID(),
        degree: MillariumDegree,
        title: String,
        courseNumber: String? = nil,   // 👈 neu
        notes: String? = nil,
        isCompleted: Bool = false,
        fileLinks: [FileLink] = [],
        folderURL: URL? = nil,
        children: [Millarium] = [],
        reminderIdentifier: String? = nil
    ) {
        self.id = id
        self.degree = degree
        self.title = title
        self.courseNumber = courseNumber
        self.notes = notes
        self.isCompleted = isCompleted
        self.fileLinks = fileLinks
        self.folderURL = folderURL
        self.children = children
        self.reminderIdentifier = reminderIdentifier
    }
    
    // MARK: - ProgressComputable
    
    public var childCount: Int {
        children.count
    }
    
    public var childProgresses: [Double] {
            children.map { $0.progress }
    }
    
    // MARK: - Abgeleitete Eigenschaften
    
    /// Ist dieser Knoten das Millarium höchster Ordnung?
    /// = hat keine Kinder
    public var isLeaf: Bool {
        children.isEmpty
    }
    
    // MARK: - Mutation
    
    /// Fügt ein Kind hinzu. Wenn dieser Knoten vorher ein Blatt war,
    /// wird `isCompleted` zurückgesetzt (weil er jetzt Container ist).
    public mutating func addChild(_ child: Millarium) {
        children.append(child)
        if !children.isEmpty {
            isCompleted = false
        }
    }
    
    public mutating func removeChild(id: UUID) {
        children.removeAll { $0.id == id }
    }
    
    /// Sucht rekursiv nach einem Millarium mit gegebener ID
    public func find(id: UUID) -> Millarium? {
        if self.id == id { return self }
        for child in children {
            if let found = child.find(id: id) { return found }
        }
        return nil
    }
    
    /// Wendet eine Mutation auf einen Knoten mit gegebener ID an
    public mutating func update(id: UUID, mutation: (inout Millarium) -> Void) -> Bool {
        if self.id == id {
            mutation(&self)
            return true
        }
        for i in children.indices {
            if children[i].update(id: id, mutation: mutation) {
                return true
            }
        }
        return false
    }
    
    /// Fügt ein Kind zu einem Knoten mit gegebener ID hinzu
    public mutating func addChild(to parentId: UUID, child: Millarium) -> Bool {
        return update(id: parentId) { node in
            node.addChild(child)
        }
    }
    
    /// Entfernt ein Kind aus einem Knoten mit gegebener ID
    public mutating func removeChild(from parentId: UUID, childId: UUID) -> Bool {
        return update(id: parentId) { node in
            node.removeChild(id: childId)
        }
    }
}

// MARK: - FileLink

public struct FileLink: Identifiable, Equatable {
    public let id: UUID
    public var title: String
    public var url: URL
    public var icon: FileLinkIcon
    
    public init(id: UUID = UUID(), title: String, url: URL, icon: FileLinkIcon) {
        self.id = id
        self.title = title
        self.url = url
        self.icon = icon
    }
}

public enum FileLinkIcon: String, CaseIterable {
    case video
    case pdf
    case link
    case folder
    case document
    case keynote
    case image
    case audio
    case unknown
    
    /// Erkennt den Icon-Typ anhand der Dateiendung
    public static func detect(from url: URL) -> FileLinkIcon {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "mp4", "mov", "avi", "mkv", "m4v": return .video
        case "pdf": return .pdf
        case "key": return .keynote
        case "doc", "docx", "txt", "rtf", "pages": return .document
        case "jpg", "jpeg", "png", "gif", "heic", "tiff": return .image
        case "mp3", "wav", "aac", "m4a": return .audio
        case "": return .folder
        default: return .unknown
        }
    }
    
    public var sfSymbol: String {
        switch self {
        case .video: return "play.rectangle.fill"
        case .pdf: return "doc.fill"
        case .link: return "link"
        case .folder: return "folder.fill"
        case .document: return "doc.text.fill"
        case .keynote: return "rectangle.on.rectangle.fill"
        case .image: return "photo.fill"
        case .audio: return "waveform"
        case .unknown: return "doc.fill"
        }
    }
}

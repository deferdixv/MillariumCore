//
//  FileSystemService.swift
//  MyTool
//
//  Created by Ferdinand Reichart on 20.09.2026.
//


import Foundation

#if canImport(AppKit)
import AppKit
#endif


/// Kapselt alle Dateisystem-Operationen rund um den Root-Ordner.
public final class FileSystemService {
    
    private let fileManager = FileManager.default
    
    public init() {}
    
    // MARK: - Root-Verwaltung
    
    public func setRootFolder(_ url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else {
            throw FileSystemError.rootNotFound
        }
        // In der App: Bookmark speichern
    }
    
    // MARK: - Ordner anlegen
    
    /// Erstellt einen Kurs-Ordner im Root.
    /// Format: `Name-[KURSNUMMER]`
    public func createCourseFolder(
        in root: URL,
        title: String,
        courseNumber: String
    ) throws -> URL {
        let folderName = "\(title)-[\(courseNumber)]"
        let url = root.appendingPathComponent(folderName, isDirectory: true)
        
        if fileManager.fileExists(atPath: url.path) {
            throw FileSystemError.folderAlreadyExists(url)
        }
        
        try fileManager.createDirectory(at: url, withIntermediateDirectories: false)
        return url
    }
    
    /// Erstellt einen Kapitel-Ordner in einem Kurs-Ordner.
    /// Format: `XX Kapitelname`
    public func createChapterFolder(
        in course: URL,
        order: Int,
        title: String
    ) throws -> URL {
        let orderString = String(format: "%02d", order)
        let folderName = "\(orderString) \(title)"
        let url = course.appendingPathComponent(folderName, isDirectory: true)
        
        if fileManager.fileExists(atPath: url.path) {
            throw FileSystemError.folderAlreadyExists(url)
        }
        
        try fileManager.createDirectory(at: url, withIntermediateDirectories: false)
        return url
    }
    
    /// Erstellt einen Subchapter-Ordner in einem Kapitel-Ordner.
    /// Format: `XX.YY Subchaptername`
    public func createSubchapterFolder(
        in chapter: URL,
        parentOrder: Int,
        subOrder: Int,
        title: String
    ) throws -> URL {
        let parentString = String(format: "%02d", parentOrder)
        let subString = String(format: "%02d", subOrder)
        let folderName = "\(parentString).\(subString) \(title)"
        let url = chapter.appendingPathComponent(folderName, isDirectory: true)
        
        if fileManager.fileExists(atPath: url.path) {
            throw FileSystemError.folderAlreadyExists(url)
        }
        
        try fileManager.createDirectory(at: url, withIntermediateDirectories: false)
        return url
    }
    
    // MARK: - Ordner löschen
    
    /// Löscht einen Kapitel-Ordner und verschiebt die enthaltenen Dateien
    /// eine Ebene nach oben (in den Kurs-Ordner).
    public func deleteChapterFolderMovingContentsUp(_ chapter: URL) throws {
        let parent = chapter.deletingLastPathComponent()
        let contents = try fileManager.contentsOfDirectory(
            at: chapter,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        
        for item in contents {
            let destination = parent.appendingPathComponent(item.lastPathComponent)
            var finalDestination = destination
            
            // Konfliktbehandlung: Umbenennen mit Suffix
            var counter = 1
            while fileManager.fileExists(atPath: finalDestination.path) {
                finalDestination = parent.appendingPathComponent(
                    "\(item.deletingPathExtension().lastPathComponent)-\(counter).\(item.pathExtension)"
                )
                counter += 1
            }
            
            try fileManager.moveItem(at: item, to: finalDestination)
        }
        
        try fileManager.removeItem(at: chapter)
    }
    
    // MARK: - Dateien verlinken
    
    /// Kopiert eine externe Datei in den Zielordner und gibt die neue URL zurück.
    public func importFile(_ source: URL, to destination: URL) throws -> URL {
        let target = destination.appendingPathComponent(source.lastPathComponent)
        
        if fileManager.fileExists(atPath: target.path) {
            throw FileSystemError.folderAlreadyExists(target)
        }
        
        try fileManager.copyItem(at: source, to: target)
        return target
    }
    
    /// Prüft, ob eine Datei/Ordner existiert.
    public func exists(_ url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }
    
    /// Öffnet eine Datei/Ordner im Finder.
    public func revealInFinder(_ url: URL) {
            #if canImport(AppKit)
            NSWorkspace.shared.activateFileViewerSelecting([url])
            #endif
    }
}

public enum FileSystemError: LocalizedError {
    case rootNotFound
    case folderAlreadyExists(URL)
    case invalidCourseName(String)
    
    public var errorDescription: String? {
        switch self {
        case .rootNotFound:
            return "Der Root-Ordner wurde nicht gefunden."
        case .folderAlreadyExists(let url):
            return "Der Ordner existiert bereits: \(url.lastPathComponent)"
        case .invalidCourseName(let name):
            return "Ungültiger Kursname: \(name). Erwartet: Name-[KURSNUMMER]"
        }
    }
}

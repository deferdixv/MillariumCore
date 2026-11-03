import Foundation

/// Parst die Ordnerstruktur eines Root-Ordners in einen Millarium-Baum.
///
/// Erwartete Struktur (zwei Ebenen):
/// ```
/// Root/
/// ├── Analysis 1 [MA101]/          ← Kurs
/// │   ├── 01 Folgen/                ← Kapitel
/// │   ├── 02 Reihen/
/// │   ├── 03 Differenziale/
/// │   └── 04 Integrale/
/// └── Lineare Algebra [MA201]/
/// ```
///
/// Subchapters, Steps und Substeps werden **nicht** aus dem Dateisystem
/// gelesen — die entstehen erst durch Nutzerarbeit im GUI oder CLI.
public enum FolderParser {

    public static func parseCourses(in rootFolder: URL) throws -> [Millarium] {
        let contents = try FileManager.default.contentsOfDirectory(
            at: rootFolder,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        return contents
            .filter { isDirectory($0) }
            .compactMap { parseCourseFolder($0) }
            .sorted { $0.title < $1.title }
    }

    public static func parseCourseFolder(_ url: URL) -> Millarium? {
        let name = url.lastPathComponent
        guard let parsed = parseCourseName(name) else { return nil }

        var course = Millarium(
            degree: .course,
            title: parsed.title,
            courseNumber: parsed.courseNumber,
            folderURL: url
        )

        if let chapters = try? parseChapterFolders(in: url) {
            for chapter in chapters {
                course.addChild(chapter)
            }
        }
        return course
    }

    /// Erkennt beide Formate:
    ///   `Analysis 1 [MA101]`    → ("Analysis 1", "MA101")
    ///   `Analysis-[MATH1-01]`   → ("Analysis", "MATH1-01")
    public static func parseCourseName(_ name: String) -> (title: String, courseNumber: String)? {
        let pattern = #"^(.+?)\s*[-]?\s*\[([^\]]+)\]\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = name as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: name, range: range),
              match.range(at: 1).location != NSNotFound,
              match.range(at: 2).location != NSNotFound else { return nil }
        let title = ns.substring(with: match.range(at: 1))
            .trimmingCharacters(in: .whitespaces)
        let number = ns.substring(with: match.range(at: 2))
            .trimmingCharacters(in: .whitespaces)
        return (title, number)
    }

    public static func parseChapterFolders(in courseFolder: URL) throws -> [Millarium] {
        let contents = try FileManager.default.contentsOfDirectory(
            at: courseFolder,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        return contents
            .filter { isDirectory($0) }
            .compactMap { parseChapterFolder($0) }
            .sorted { $0.title < $1.title }
    }

    /// Erwartet `01 Folgen` → Kapitel "Folgen" mit Order 1.
    public static func parseChapterFolder(_ url: URL) -> Millarium? {
        let name = url.lastPathComponent
        guard let (_, title) = parseNumberedName(name) else { return nil }
        return Millarium(degree: .chapter, title: title, folderURL: url)
    }

    // MARK: - Helpers

    private static func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        return isDir.boolValue
    }

    /// Parst `04 Deutsches Kaiserreich` → `(4, "Deutsches Kaiserreich")`
    public static func parseNumberedName(_ name: String) -> (Int, String)? {
        let pattern = #"^(\d+)\s+(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = name as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: name, range: range),
              match.range(at: 1).location != NSNotFound,
              match.range(at: 2).location != NSNotFound else { return nil }
        guard let order = Int(ns.substring(with: match.range(at: 1))) else { return nil }
        let title = ns.substring(with: match.range(at: 2))
        return (order, title)
    }
}

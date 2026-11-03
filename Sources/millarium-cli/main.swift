//
//  CLIStore.swift
//  MillariumCore
//
//  Created by Ferdinand Reichart on 21.09.2026.
//


import Foundation
import MillariumCore

// ═════════════════r══════════════════════════════════════════════════
// LOKALE PERSISTENZ (nur für CLI-Testzwecke)
// Das Package selbst ist persistenz-frei. Die CLI braucht aber
// einen Zustand zwischen Befehlen, also nutzen wir lokales JSON.
// ═══════════════════════════════════════════════════════════════════

// Wir brauchen Codable für den lokalen Store. Da der Millarium-Struct
// das nicht mehr hat, wrappen wir ihn in einen kleinen CLI-Layer.

struct CLIStore: Codable {
    var root: CLINode?
}

struct CLINode: Codable {
    var id: UUID
    var degree: Int          // rawValue des MillariumDegree
    var title: String
    var notes: String?
    var isCompleted: Bool
    var children: [CLINode]

    init(from millarium: Millarium) {
        self.id = millarium.id
        self.degree = millarium.degree.rawValue
        self.title = millarium.title
        self.notes = millarium.notes
        self.isCompleted = millarium.isCompleted
        self.children = millarium.children.map { CLINode(from: $0) }
    }

    func toMillarium() -> Millarium {
        guard let deg = MillariumDegree(rawValue: degree) else {
            fatalError("Ungültiger Degree-Wert: \(degree)")
        }
        return Millarium(
            id: id,
            degree: deg,
            title: title,
            notes: notes,
            isCompleted: isCompleted,
            children: children.map { $0.toMillarium() }
        )
    }
}

// ═══════════════════════════════════════════════════════════════════
// CLI STATE
// ═══════════════════════════════════════════════════════════════════

let storeURL = FileManager.default
    .homeDirectoryForCurrentUser
    .appendingPathComponent(".millarium-cli.json")

var currentRoot: Millarium?

func loadStore() {
    guard FileManager.default.fileExists(atPath: storeURL.path) else {
        currentRoot = nil
        return
    }
    do {
        let data = try Data(contentsOf: storeURL)
        let cliStore = try JSONDecoder().decode(CLIStore.self, from: data)
        currentRoot = cliStore.root?.toMillarium()
    } catch {
        print("⚠️ Konnte Store nicht laden: \(error)")
        currentRoot = nil
    }
}

func saveStore() {
    do {
        let cliStore: CLIStore
        if let root = currentRoot {
            cliStore = CLIStore(root: CLINode(from: root))
        } else {
            cliStore = CLIStore(root: nil)
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(cliStore)
        try data.write(to: storeURL, options: .atomic)
    } catch {
        print("⚠️ Konnte Store nicht speichern: \(error)")
    }
}

// ═══════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════

func printHelp() {
    print("""

    ╔══════════════════════════════════════════════════════════════╗
    ║              Millarium CLI - Test Interface                  ║
    ╚══════════════════════════════════════════════════════════════╝

    PERSISTENZ:
      clear                           Setzt den Store zurück
      save                            Speichert manuell
      load                            Lädt neu
      path                            Zeigt den Speicherpfad

    STRUKTUR:
      init-course <name>              Erstellt einen Kurs (Grad 1) als Root
      add-chapter <parentId> <title>  Fügt ein Kapitel hinzu
      add-part <parentId> <title>     Fügt einen Teil hinzu
      add-subchapter <parentId> <t>   Fügt ein Unterkapitel hinzu
      add-step <parentId> <title>     Fügt einen Schritt hinzu
      add-substep <parentId> <title>  Fügt einen Unterschritt hinzu
      remove <parentId> <childId>     Entfernt ein Kind

    FORTSCHRITT:
      toggle <id>                     Hakt ein Blatt ab
      progress [<id>]                 Zeigt den Fortschritt (root falls id fehlt)
      tree                            Zeigt den gesamten Baum mit Fortschritt

    PARSER:
      parse <rootPath>                Parst einen Root-Ordner und zeigt die Struktur
      import <rootPath>               Importiert den geparsten Baum als Root

    TESTS:
      test-progress                   Führt die eingebauten Progress-Tests aus
      demo                            Baut eine Demo-Struktur auf

    EXIT:
      quit / exit                     Beendet die CLI

    """)
}

func printTree(_ node: Millarium, indent: Int = 0) {
    let prefix = String(repeating: "  ", count: indent)
    let progressPercent = ProgressCalculator.percent(node.progress)
    let status = node.isLeaf ? (node.isCompleted ? "✓" : "○") : " "
    let degreeLabel = "[\(node.degree.rawValue)]"

    print("\(prefix)\(status) \(degreeLabel) \(node.title) - \(progressPercent)%")

    if let notes = node.notes, !notes.isEmpty {
        print("\(prefix)   📝 \(notes.prefix(60))\(notes.count > 60 ? "..." : "")")
    }

    for link in node.fileLinks {
        print("\(prefix)   \(link.icon.sfSymbol) \(link.title)")
    }

    for child in node.children {
        printTree(child, indent: indent + 1)
    }
}

// ═══════════════════════════════════════════════════════════════════
// COMMAND DISPATCH
// ═══════════════════════════════════════════════════════════════════

func executeCommand(_ args: [String]) {
    guard !args.isEmpty else {
        printHelp()
        return
    }

    let command = args[0]
    let params = Array(args.dropFirst())

    switch command {

    // MARK: Persistenz

    case "clear":
        currentRoot = nil
        saveStore()
        print("✅ Store geleert")

    case "save":
        saveStore()
        print("✅ Gespeichert")

    case "load":
        loadStore()
        print("✅ Neu geladen")

    case "path":
        print("📁 \(storeURL.path)")

    // MARK: Struktur

    case "init-course":
        guard let name = params.first else {
            print("❌ Verwendung: init-course <name>")
            return
        }
        let course = Millarium(degree: .course, title: name)
        currentRoot = course
        saveStore()
        print("✅ Kurs erstellt: \(name)")
        print("   ID: \(course.id)")

    case "add-chapter":
        guard params.count >= 2,
              let parentId = UUID(uuidString: params[0]),
              var root = currentRoot else {
            print("❌ Verwendung: add-chapter <parentId> <title>")
            return
        }
        let title = params.dropFirst().joined(separator: " ")
        guard let parent = root.find(id: parentId),
              let nextDegree = parent.degree.deeper else {
            print("❌ Parent nicht gefunden oder kein tieferer Grad möglich")
            return
        }
        let chapter = Millarium(degree: nextDegree, title: title)
        _ = root.addChild(to: parentId, child: chapter)
        currentRoot = root
        saveStore()
        print("✅ Kapitel hinzugefügt: \(title)")
        print("   ID: \(chapter.id)")

    case "add-part":
        guard params.count >= 2,
              let parentId = UUID(uuidString: params[0]),
              var root = currentRoot else {
            print("❌ Verwendung: add-part <parentId> <title>")
            return
        }
        let title = params.dropFirst().joined(separator: " ")
        let part = Millarium(degree: .part, title: title)
        _ = root.addChild(to: parentId, child: part)
        currentRoot = root
        saveStore()
        print("✅ Teil hinzugefügt: \(title)")
        print("   ID: \(part.id)")

    case "add-subchapter":
        guard params.count >= 2,
              let parentId = UUID(uuidString: params[0]),
              var root = currentRoot else {
            print("❌ Verwendung: add-subchapter <parentId> <title>")
            return
        }
        let title = params.dropFirst().joined(separator: " ")
        let sub = Millarium(degree: .subchapter, title: title)
        _ = root.addChild(to: parentId, child: sub)
        currentRoot = root
        saveStore()
        print("✅ Unterkapitel hinzugefügt: \(title)")
        print("   ID: \(sub.id)")

    case "add-step":
        guard params.count >= 2,
              let parentId = UUID(uuidString: params[0]),
              var root = currentRoot else {
            print("❌ Verwendung: add-step <parentId> <title>")
            return
        }
        let title = params.dropFirst().joined(separator: " ")
        let step = Millarium(degree: .step, title: title)
        _ = root.addChild(to: parentId, child: step)
        currentRoot = root
        saveStore()
        print("✅ Schritt hinzugefügt: \(title)")
        print("   ID: \(step.id)")

    case "add-substep":
        guard params.count >= 2,
              let parentId = UUID(uuidString: params[0]),
              var root = currentRoot else {
            print("❌ Verwendung: add-substep <parentId> <title>")
            return
        }
        let title = params.dropFirst().joined(separator: " ")
        let sub = Millarium(degree: .substep, title: title)
        _ = root.addChild(to: parentId, child: sub)
        currentRoot = root
        saveStore()
        print("✅ Unterschritt hinzugefügt: \(title)")
        print("   ID: \(sub.id)")

    case "remove":
        guard params.count >= 2,
              let parentId = UUID(uuidString: params[0]),
              let childId = UUID(uuidString: params[1]),
              var root = currentRoot else {
            print("❌ Verwendung: remove <parentId> <childId>")
            return
        }
        if root.removeChild(from: parentId, childId: childId) {
            currentRoot = root
            saveStore()
            print("✅ Kind entfernt")
        } else {
            print("❌ Nicht gefunden")
        }

    // MARK: Fortschritt

    case "toggle":
        guard let idString = params.first,
              let id = UUID(uuidString: idString),
              var root = currentRoot else {
            print("❌ Verwendung: toggle <id>")
            return
        }
        if root.update(id: id, mutation: { node in
            if node.isLeaf { node.isCompleted.toggle() }
        }) {
            currentRoot = root
            saveStore()
            if let node = root.find(id: id) {
                print("✅ \(node.title) → \(node.isCompleted ? "erledigt" : "offen")")
            }
        } else {
            print("❌ Nicht gefunden")
        }

    case "progress":
        let node: Millarium?
        if let idString = params.first, let id = UUID(uuidString: idString) {
            node = currentRoot?.find(id: id)
        } else {
            node = currentRoot
        }
        guard let node else {
            print("❌ Kein Knoten")
            return
        }
        let p = ProgressCalculator.percent(node.progress)
        print("📊 \(node.title): \(p)%")

    case "tree":
        guard let root = currentRoot else {
            print("⚠️ Kein Baum vorhanden. Nutze 'init-course' oder 'demo'")
            return
        }
        print("")
        printTree(root)
        print("")

    // MARK: Parser

    case "parse":
        guard let path = params.first else {
            print("❌ Verwendung: parse <rootPath>")
            return
        }
        let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        do {
            let courses = try FolderParser.parseCourses(in: url)
            print("📁 Gefundene Kurse: \(courses.count)")
            for course in courses {
                printTree(course)
            }
        } catch {
            print("❌ Fehler: \(error)")
        }

    case "import":
        guard let path = params.first else {
            print("❌ Verwendung: import <rootPath>")
            return
        }
        let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        do {
            let courses = try FolderParser.parseCourses(in: url)
            guard let first = courses.first else {
                print("⚠️ Keine Kurse gefunden")
                return
            }
            if courses.count == 1 {
                currentRoot = first
                saveStore()
                print("✅ Kurs importiert: \(first.title)")
            } else {
                var root = Millarium(degree: .course, title: "Root")
                for course in courses {
                    root.addChild(course)
                }
                currentRoot = root
                saveStore()
                print("✅ \(courses.count) Kurse importiert")
            }
        } catch {
            print("❌ Fehler: \(error)")
        }

    // MARK: Tests

    case "test-progress":
        runProgressTests()

    case "demo":
        buildDemo()

    // MARK: Exit

    case "quit", "exit":
        print("👋 Auf Wiedersehen")
        exit(0)

    default:
        print("❌ Unbekannter Befehl: \(command)")
        printHelp()
    }
}

// ═══════════════════════════════════════════════════════════════════
// DEMO
// ═══════════════════════════════════════════════════════════════════

func buildDemo() {
    var course = Millarium(degree: .course, title: "Analysis")
    let courseId = course.id

    // Kapitel 1
    var ch1 = Millarium(degree: .chapter, title: "Grundlagen")
    let ch1Id = ch1.id

    // Unterkapitel 1.1
    var sub11 = Millarium(degree: .subchapter, title: "Mengen")
    let sub11Id = sub11.id
    sub11.addChild(Millarium(degree: .step, title: "Definition lesen", isCompleted: true))
    sub11.addChild(Millarium(degree: .step, title: "Übungen 1-5"))
    sub11.addChild(Millarium(degree: .step, title: "Quizlet"))

    // Unterkapitel 1.2
    var sub12 = Millarium(degree: .subchapter, title: "Funktionen")
    let sub12Id = sub12.id
    sub12.addChild(Millarium(degree: .step, title: "Vorlesung", isCompleted: true))
    sub12.addChild(Millarium(degree: .step, title: "Skript", isCompleted: true))

    ch1.addChild(sub11)
    ch1.addChild(sub12)

    // Kapitel 2
    var ch2 = Millarium(degree: .chapter, title: "Folgen")
    let ch2Id = ch2.id
    var sub21 = Millarium(degree: .subchapter, title: "Grenzwerte")
    let sub21Id = sub21.id
    sub21.addChild(Millarium(degree: .step, title: "Video 1"))
    sub21.addChild(Millarium(degree: .step, title: "Video 2"))
    ch2.addChild(sub21)

    course.addChild(ch1)
    course.addChild(ch2)

    currentRoot = course
    saveStore()

    print("✅ Demo-Struktur erstellt")
    print("   Kurs-ID: \(courseId)")
    print("   Kapitel 1: \(ch1Id)")
    print("   Kapitel 2: \(ch2Id)")
    print("   Unterkapitel 1.1: \(sub11Id)")
    print("   Unterkapitel 1.2: \(sub12Id)")
    print("   Unterkapitel 2.1: \(sub21Id)")
    print("")
    printTree(course)
}

// ═══════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════

func runProgressTests() {
    print("")
    print("🧪 Progress-Tests")
    print("─".padding(toLength: 60, withPad: "─", startingAt: 0))

    var passed = 0
    var failed = 0

    func assert(_ condition: Bool, _ message: String) {
        if condition {
            print("  ✅ \(message)")
            passed += 1
        } else {
            print("  ❌ \(message)")
            failed += 1
        }
    }

    // Test 1
    var leaf = Millarium(degree: .step, title: "Step", isCompleted: false)
    assert(leaf.progress == 0.0, "Blatt (nicht erledigt) → 0.0")

    // Test 2
    leaf.isCompleted = true
    assert(leaf.progress == 1.0, "Blatt (erledigt) → 1.0")

    // Test 3
    var container = Millarium(degree: .subchapter, title: "Sub")
    container.addChild(Millarium(degree: .step, title: "A", isCompleted: true))
    container.addChild(Millarium(degree: .step, title: "B", isCompleted: false))
    assert(container.progress == 0.5, "Container 1/2 → 0.5")

    // Test 4
    var container3 = Millarium(degree: .subchapter, title: "Sub")
    container3.addChild(Millarium(degree: .step, title: "A", isCompleted: true))
    container3.addChild(Millarium(degree: .step, title: "B", isCompleted: true))
    container3.addChild(Millarium(degree: .step, title: "C", isCompleted: false))
    let p = container3.progress
    assert(abs(p - 0.6667) < 0.001, "Container 2/3 → 0.6667")

    // Test 5
    var ch = Millarium(degree: .chapter, title: "Ch")
    var s1 = Millarium(degree: .subchapter, title: "S1")
    s1.addChild(Millarium(degree: .step, title: "a", isCompleted: true))
    s1.addChild(Millarium(degree: .step, title: "b", isCompleted: true))
    var s2 = Millarium(degree: .subchapter, title: "S2")
    s2.addChild(Millarium(degree: .step, title: "c", isCompleted: false))
    s2.addChild(Millarium(degree: .step, title: "d", isCompleted: false))
    ch.addChild(s1)
    ch.addChild(s2)
    assert(ch.progress == 0.5, "Chapter mit S1=100%, S2=0% → 0.5")

    // Test 6
    let empty = Millarium(degree: .subchapter, title: "Empty")
    assert(empty.progress == 0.0, "Leerer Container (Blatt) → 0.0")

    // Test 7
    let emptyDone = Millarium(degree: .subchapter, title: "Empty", isCompleted: true)
    assert(emptyDone.progress == 1.0, "Leerer Container erledigt → 1.0")

    print("─".padding(toLength: 60, withPad: "─", startingAt: 0))
    print("  📊 \(passed) bestanden, \(failed) fehlgeschlagen")
    print("")
}

// ═══════════════════════════════════════════════════════════════════
// MAIN LOOP
// ═══════════════════════════════════════════════════════════════════

loadStore()

print("")
print("╔══════════════════════════════════════════════════════════════╗")
print("║              Millarium CLI - Test Interface                  ║")
print("║                                                              ║")
print("║  Tippe 'help' für eine Liste der Befehle.                    ║")
print("╚══════════════════════════════════════════════════════════════╝")
print("")

while true {
    print("millarium> ", terminator: "")
    guard let input = readLine() else { break }
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

    if trimmed.isEmpty { continue }
    if trimmed == "help" || trimmed == "?" {
        printHelp()
        continue
    }

    let args = trimmed.split(separator: " ").map(String.init)
    executeCommand(args)
}

//
//  FileSystemHelper.swift
//  Nova
//
//  Created by Maxime Dondon on 25/08/2025.
//

import Foundation
import AppKit

enum FSHelper {
    static let fm = FileManager.default

    static func pickDirectory(startingAt url: URL? = nil) -> URL? {
        let panel = NSOpenPanel()
        panel.message = "Choisissez un dossier"
        panel.prompt = "Choisir"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true // Allow creating new folders
        panel.allowsMultipleSelection = false
        if let url { panel.directoryURL = url }
        return panel.runModal() == .OK ? panel.urls.first : nil
    }

    static func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    static func exists(at url: URL?) -> Bool {
        guard let url else { return false }
        var isDir: ObjCBool = false
        let ok = fm.fileExists(atPath: url.path, isDirectory: &isDir)
        return ok && isDir.boolValue
    }

    /// Sanitise un nom pour utilisation en nom de dossier (retire slash etc.)
    static func sanitizedFolderName(from name: String) -> String {
        let illegal = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        var s = name.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.components(separatedBy: illegal).joined(separator: "-")
        if s.isEmpty { s = "Projet" }
        return s
    }

    /// Crée l'arborescence d'un projet sous `root` avec le nom `folderName`.
    /// Retourne l'URL du dossier projet si création OK.
    static func createProjectFolderStructure(root: URL, folderName: String) throws -> URL {
        let projectURL = root.appendingPathComponent(folderName, isDirectory: true)
        if !fm.fileExists(atPath: projectURL.path) {
            try fm.createDirectory(at: projectURL, withIntermediateDirectories: true, attributes: nil)
        }
        // Required subfolders
        let subs = [
            "00 IN",
            "01 ASSETS",
            "02 AI",
            "03 3D",
            "04 AUDIO",
            "05 AEP",
            "06 CAVALRY",
            "07 SORTIES",
            "08 LIVRABLE"
        ]
        for sub in subs {
            let subURL = projectURL.appendingPathComponent(sub, isDirectory: true)
            if !fm.fileExists(atPath: subURL.path) {
                try fm.createDirectory(at: subURL, withIntermediateDirectories: true, attributes: nil)
            }
        }
        return projectURL
    }
    
    /// Stocker bookmark pour accès sandboxé
    static func saveBookmark(for url: URL, key: String) {
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmarkData, forKey: key)
        } catch {
            print("Erreur bookmark: \(error)")
        }
    }
    
    /// Récupérer le bookmark
    static func resolveBookmark(forKey key: String) -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: key) else { return nil }
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale {
                saveBookmark(for: url, key: key)
            }
            return url
        } catch {
            print("Erreur résolution bookmark: \(error)")
            return nil
        }
    }


    /// Renomme un dossier (déplace) et déplace aussi project.json
    static func renameFolder(at url: URL, to newName: String) throws -> URL {
        let parent = url.deletingLastPathComponent()
        let newURL = parent.appendingPathComponent(newName, isDirectory: true)
        try fm.moveItem(at: url, to: newURL)
        // Move project.json if it exists
        let oldJson = url.appendingPathComponent("project.json")
        let newJson = newURL.appendingPathComponent("project.json")
        if fm.fileExists(atPath: oldJson.path) {
            try fm.moveItem(at: oldJson, to: newJson)
        }
        return newURL
    }

    /// Supprime un dossier et tout son contenu (attention)
    static func deleteFolder(at url: URL) throws {
        try fm.removeItem(at: url)
    }

    /// Retourne le dernier .aep dans un dossier (comme avant)
    static func latestAEP(in folder: URL) -> URL? {
        guard let items = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) else {
            return nil
        }
        let aeps = items.filter { $0.pathExtension.lowercased() == "aep" }
        if aeps.isEmpty { return nil }
        // Try parse YYMMDD
        func parse(_ name: String) -> Date? {
            let pattern = #"(?<!\d)(\d{6})(?!\d)"#
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
            guard let m = regex.firstMatch(in: name, range: NSRange(location: 0, length: (name as NSString).length)) else { return nil }
            let token = (name as NSString).substring(with: m.range(at: 1))
            let df = DateFormatter()
            df.locale = Locale(identifier: "fr_FR")
            df.dateFormat = "yyMMdd"
            return df.date(from: token)
        }
        let labeled = aeps.map { (url: $0, date: parse($0.deletingPathExtension().lastPathComponent)) }
        if labeled.contains(where: { $0.date != nil }) {
            return labeled.sorted { lhs, rhs in
                switch (lhs.date, rhs.date) {
                case let (l?, r?): return l > r
                case (nil, _?): return false
                case (_?, nil): return true
                default: return lhs.url.lastPathComponent > rhs.url.lastPathComponent
                }
            }.first?.url
        }
        // fallback by modification date
        let meta = aeps.compactMap { url -> (URL, Date)? in
            let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
            return (url, date)
        }
        return meta.sorted { $0.1 > $1.1 }.first?.0
    }

    /// Liste tous les dossiers projets dans un dossier racine
    static func listProjectFolders(at root: URL) -> [URL] {
        guard let contents = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return []
        }
        return contents.filter { url in
            var isDir: ObjCBool = false
            return fm.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
        }
    }
}

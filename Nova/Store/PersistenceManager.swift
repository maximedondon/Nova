//
//  PersistenceManager.swift
//  Nova
//
//  Gestionnaire de persistance centralisée pour les projets
//

import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let projectsFileName = "projects.json"
    
    private init() {}
    
    /// Récupère l'URL du fichier de persistance dans Application Support
    private var projectsFileURL: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let appFolder = appSupport.appendingPathComponent("Nova", isDirectory: true)
        
        // Créer le dossier s'il n'existe pas
        if !FileManager.default.fileExists(atPath: appFolder.path) {
            try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true, attributes: nil)
        }
        
        return appFolder.appendingPathComponent(projectsFileName)
    }
    
    /// Sauvegarde la liste des projets
    func saveProjects(_ projects: [Project]) {
        guard let fileURL = projectsFileURL else {
            print("❌ Impossible de déterminer l'URL du fichier de sauvegarde")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(projects)
            try data.write(to: fileURL, options: .atomic)
            print("✅ Projets sauvegardés: \(projects.count) projet(s)")
        } catch {
            print("❌ Erreur sauvegarde projets: \(error)")
        }
    }
    
    /// Charge la liste des projets
    func loadProjects() -> [Project] {
        guard let fileURL = projectsFileURL else {
            print("❌ Impossible de déterminer l'URL du fichier de chargement")
            return []
        }
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("ℹ️ Aucun fichier de projets trouvé, démarrage avec liste vide")
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let projects = try decoder.decode([Project].self, from: data)
            print("✅ Projets chargés: \(projects.count) projet(s)")
            return projects
        } catch {
            print("❌ Erreur chargement projets: \(error)")
            return []
        }
    }
    
    /// Exporte les projets vers un fichier choisi par l'utilisateur
    func exportProjects(_ projects: [Project], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(projects)
        try data.write(to: url, options: .atomic)
    }
    
    /// Importe des projets depuis un fichier choisi par l'utilisateur
    func importProjects(from url: URL) throws -> [Project] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Project].self, from: data)
    }
    
    /// Récupère l'URL du dossier de persistance (utile pour debug)
    func getPersistenceFolder() -> URL? {
        return projectsFileURL?.deletingLastPathComponent()
    }
}

//
//  ProjectFolder.swift
//  Nova
//
//  Modèle pour gérer plusieurs dossiers de projets
//

import Foundation

struct ProjectFolder: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var bookmarkData: Data  // Security-scoped bookmark
    var isDefault: Bool
    var createdAt: Date
    
    // URL résolue (non persistée, reconstruite à partir du bookmark)
    var url: URL? {
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale {
                print("⚠️ Bookmark obsolète pour \(name)")
            }
            return url
        } catch {
            print("❌ Erreur résolution bookmark pour \(name): \(error)")
            return nil
        }
    }
    
    init(id: UUID = UUID(), name: String, bookmarkData: Data, isDefault: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.bookmarkData = bookmarkData
        self.isDefault = isDefault
        self.createdAt = createdAt
    }
    
    /// Créer un ProjectFolder depuis une URL (crée le bookmark automatiquement)
    static func from(url: URL, name: String? = nil, isDefault: Bool = false) throws -> ProjectFolder {
        let bookmarkData = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
        let folderName = name ?? url.lastPathComponent
        return ProjectFolder(name: folderName, bookmarkData: bookmarkData, isDefault: isDefault)
    }
    
    /// Démarre l'accès sécurisé au dossier
    @discardableResult
    func startAccessing() -> Bool {
        guard let url = url else { return false }
        return url.startAccessingSecurityScopedResource()
    }
    
    /// Arrête l'accès sécurisé au dossier
    func stopAccessing() {
        guard let url = url else { return }
        url.stopAccessingSecurityScopedResource()
    }
}

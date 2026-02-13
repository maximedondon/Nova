//
//  SettingsManager.swift
//  Nova
//
//  Created by Maxime Dondon on 05/09/2025.
//

import Foundation

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    private let foldersKey = "projectFolders.v2"
    private let legacyBookmarkKey = "projectsFolderBookmark" // Pour migration

    @Published var projectFolders: [ProjectFolder] = []
    @Published var projectsFolderPublished: URL? = nil // Deprecated, kept for compatibility

    private var accessingFolders: Set<UUID> = []

    private init() {
        loadFolders()
        // Pour compatibilité, on publie le dossier par défaut
        if let defaultFolder = defaultFolder {
            projectsFolderPublished = defaultFolder.url
        }
    }

    // MARK: - Computed Properties
    
    /// Récupère le dossier par défaut
    var defaultFolder: ProjectFolder? {
        projectFolders.first { $0.isDefault } ?? projectFolders.first
    }
    
    /// Récupère l'URL du dossier par défaut (pour compatibilité)
    var projectsFolder: URL? {
        defaultFolder?.url
    }

    // MARK: - Folder Management
    
    private func loadFolders() {
        // Essayer de charger les nouveaux dossiers
        if let data = UserDefaults.standard.data(forKey: foldersKey) {
            do {
                projectFolders = try JSONDecoder().decode([ProjectFolder].self, from: data)
                print("✅ Chargé \(projectFolders.count) dossier(s) de projets")
                return
            } catch {
                print("❌ Erreur chargement dossiers: \(error)")
            }
        }
        
        // Migration: charger l'ancien système
        if let bookmarkData = UserDefaults.standard.data(forKey: legacyBookmarkKey) {
            let folder = ProjectFolder(name: "Projets", bookmarkData: bookmarkData, isDefault: true)
            projectFolders = [folder]
            saveFolders()
            print("✅ Migration de l'ancien dossier vers le nouveau système")
            // Supprimer l'ancien bookmark
            UserDefaults.standard.removeObject(forKey: legacyBookmarkKey)
        }
    }
    
    private func saveFolders() {
        do {
            let data = try JSONEncoder().encode(projectFolders)
            UserDefaults.standard.set(data, forKey: foldersKey)
            // Mettre à jour la published property pour compatibilité
            if let defaultFolder = defaultFolder {
                projectsFolderPublished = defaultFolder.url
            }
        } catch {
            print("❌ Erreur sauvegarde dossiers: \(error)")
        }
    }
    
    /// Ajoute un nouveau dossier de projets
    func addFolder(_ url: URL, name: String? = nil, setAsDefault: Bool = false) throws {
        // Créer le bookmark
        let folder = try ProjectFolder.from(url: url, name: name, isDefault: setAsDefault)
        
        // Si c'est le nouveau par défaut, retirer le flag des autres
        if setAsDefault {
            for i in projectFolders.indices {
                projectFolders[i].isDefault = false
            }
        }
        
        // Si c'est le premier dossier, le mettre par défaut automatiquement
        if projectFolders.isEmpty {
            var newFolder = folder
            newFolder.isDefault = true
            projectFolders.append(newFolder)
        } else {
            projectFolders.append(folder)
        }
        
        saveFolders()
    }
    
    /// Supprime un dossier de projets
    func removeFolder(_ folder: ProjectFolder) {
        // Ne pas supprimer s'il n'y a qu'un seul dossier
        guard projectFolders.count > 1 else {
            print("⚠️ Impossible de supprimer le dernier dossier")
            return
        }
        
        // Si on supprime le dossier par défaut, définir le premier restant comme défaut
        let wasDefault = folder.isDefault
        projectFolders.removeAll { $0.id == folder.id }
        
        if wasDefault && !projectFolders.isEmpty {
            projectFolders[0].isDefault = true
        }
        
        saveFolders()
    }
    
    /// Définit un dossier comme par défaut
    func setAsDefault(_ folder: ProjectFolder) {
        for i in projectFolders.indices {
            projectFolders[i].isDefault = (projectFolders[i].id == folder.id)
        }
        saveFolders()
    }
    
    /// Renomme un dossier
    func renameFolder(_ folder: ProjectFolder, to newName: String) {
        guard let index = projectFolders.firstIndex(where: { $0.id == folder.id }) else { return }
        projectFolders[index].name = newName
        saveFolders()
    }
    
    /// Trouve un dossier par ID
    func folder(with id: UUID) -> ProjectFolder? {
        projectFolders.first { $0.id == id }
    }

    // MARK: - Legacy Compatibility (pour compatibilité avec le code existant)
    
    @available(*, deprecated, message: "Utiliser addFolder(_:name:setAsDefault:) à la place")
    func setProjectsFolder(_ url: URL) {
        do {
            // Supprimer tous les dossiers existants et en créer un nouveau
            projectFolders.removeAll()
            try addFolder(url, name: "Projets", setAsDefault: true)
        } catch {
            print("❌ Erreur setProjectsFolder: \(error)")
        }
    }

    // MARK: - Security-Scoped Access
    
    func startAccessingFolder(_ folder: ProjectFolder? = nil) -> Bool {
        let targetFolder = folder ?? defaultFolder
        guard let targetFolder = targetFolder else { return false }
        
        // Si déjà en cours d'accès, ne rien faire
        if accessingFolders.contains(targetFolder.id) {
            return true
        }
        
        let success = targetFolder.startAccessing()
        if success {
            accessingFolders.insert(targetFolder.id)
        }
        return success
    }

    func stopAccessingFolder(_ folder: ProjectFolder? = nil) {
        let targetFolder = folder ?? defaultFolder
        guard let targetFolder = targetFolder else { return }
        
        guard accessingFolders.contains(targetFolder.id) else { return }
        
        targetFolder.stopAccessing()
        accessingFolders.remove(targetFolder.id)
    }
    
    /// Pour compatibilité avec le code existant qui n'utilise pas de dossier spécifique
    func startAccessingFolder() -> Bool {
        startAccessingFolder(nil)
    }
    
    func stopAccessingFolder() {
        stopAccessingFolder(nil)
    }
}

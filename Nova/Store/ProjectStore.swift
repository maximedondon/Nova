//
//  ProjectStore.swift
//  Nova
//
//  Created by Maxime Dondon on 25/08/2025.
//

import Foundation
import SwiftUI

struct ProjectCategory: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var systemImage: String
    var isFixed: Bool

    static let all = ProjectCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, name: "Tous", systemImage: "tray", isFixed: true)
}

class ProjectStore: ObservableObject {
    @Published var projects: [Project] = []
    @Published var selection: UUID?   // UUID du projet sélectionné

    @Published var categories: [ProjectCategory] = [ProjectCategory.all]
    @Published var selectedCategoryID: UUID = ProjectCategory.all.id
    
    @Published var statuses: [ProjectStatus] = []

    // Cache to quickly lookup projects per category to avoid repeated filtering
    private var projectsByCategory: [UUID: [Project]] = [:]

    private let categoriesKey = "categories.v1"
    private let statusesKey = "statuses.v1"

    init() {
        loadCategories()
        loadStatuses()
        loadProjects()
    }
    
    // MARK: - Persistence
    
    /// Charge les projets depuis le stockage centralisé
    private func loadProjects() {
        projects = PersistenceManager.shared.loadProjects()
        rebuildProjectsByCategory()
    }
    
    /// Sauvegarde tous les projets dans le stockage centralisé
    func saveProjects() {
        PersistenceManager.shared.saveProjects(projects)
    }
    
    /// Reconstruit le cache projectsByCategory
    private func rebuildProjectsByCategory() {
        projectsByCategory = [:]
        for p in projects {
            let cat = p.categoryID ?? ProjectCategory.all.id
            projectsByCategory[cat, default: []].append(p)
        }
    }

    var filteredProjects: [Project] {
        if selectedCategoryID == ProjectCategory.all.id { return projects }
        return projectsByCategory[selectedCategoryID] ?? []
    }

    func addProject(createFolderStructure: Bool = false, in folder: ProjectFolder? = nil) {
        let newProject = Project()

        // If the user currently has a category selected (not the special "Tous" category),
        // assign the new project to that category by default.
        if selectedCategoryID != ProjectCategory.all.id {
            newProject.categoryID = selectedCategoryID
        }

        // Créer le dossier et l'arborescence si demandé
        if createFolderStructure {
            let targetFolder = folder ?? SettingsManager.shared.defaultFolder
            let didStart = SettingsManager.shared.startAccessingFolder(targetFolder)
            do {
                if let parent = targetFolder?.url {
                    let safeName = FSHelper.sanitizedFolderName(from: newProject.title)
                    let folderURL = try FSHelper.createProjectFolderStructure(root: parent, folderName: safeName)
                    newProject.rootFolderPath = folderURL.path
                    newProject.hasFolderStructure = true
                }
            } catch {
                print("Erreur création dossier projet : \(error)")
            }
            if didStart { SettingsManager.shared.stopAccessingFolder(targetFolder) }
        }

        // Update data structures on main thread
        DispatchQueue.main.async {
            self.projects.append(newProject)
            let cat = newProject.categoryID ?? ProjectCategory.all.id
            self.projectsByCategory[cat, default: []].append(newProject)
            self.selection = newProject.id
            self.saveProjects()
        }
    }

    func project(with id: UUID?) -> Project? {
        guard let id else { return nil }
        return projects.first { $0.id == id }
    }

    /// Synchronise avec le dossier de projets (optionnel, pour retrouver des dossiers existants)
    func syncWithProjectsFolder() {
        guard let parent = SettingsManager.shared.projectsFolder else {
            print("ℹ️ Aucun dossier de projets configuré")
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let didStart = SettingsManager.shared.startAccessingFolder()
            var foundFolders: [String: URL] = [:] // path -> URL
            
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: parent, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                for url in contents where url.hasDirectoryPath {
                    foundFolders[url.path] = url
                }
            } catch {
                print("Erreur scan dossier projets : \(error)")
            }
            if didStart { SettingsManager.shared.stopAccessingFolder() }

            DispatchQueue.main.async {
                // Mettre à jour les chemins des projets existants si le dossier existe
                for project in self.projects {
                    if let path = project.rootFolderPath, foundFolders[path] != nil {
                        // Le dossier existe toujours, tout va bien
                        continue
                    }
                }
                
                // Note: On ne supprime PAS les projets dont le dossier n'existe plus
                // Ils restent dans la liste pour être accessibles même si déconnectés
                print("✅ Synchronisation terminée")
            }
        }
    }

    // MARK: - Categories

    /// Create a new category and return it so the UI can immediately enter edit mode.
    func addCategory() -> ProjectCategory {
        let new = ProjectCategory(id: UUID(), name: "Nouvelle catégorie", systemImage: "folder", isFixed: false)
        categories.append(new)
        saveCategories()
        return new
    }

    func removeCategory(_ category: ProjectCategory) {
        guard !category.isFixed else { return }
        categories.removeAll { $0.id == category.id }
        // Reassign projects with removed category to .all
        for project in projects where project.categoryID == category.id {
            project.categoryID = ProjectCategory.all.id
            project.touch()
            // update cache
            DispatchQueue.main.async {
                // remove from old
                self.projectsByCategory[category.id]?.removeAll(where: { $0.id == project.id })
                // add to 'all'
                self.projectsByCategory[ProjectCategory.all.id, default: []].append(project)
            }
        }
        saveCategories()
        saveProjects()
    }

    func renameCategory(_ category: ProjectCategory, to newName: String) {
        guard let idx = categories.firstIndex(where: { $0.id == category.id }), !categories[idx].isFixed else { return }
        categories[idx].name = newName
        saveCategories()
    }

    func assign(_ project: Project, to category: ProjectCategory) {
        let oldCat = project.categoryID ?? ProjectCategory.all.id
        project.categoryID = category.id
        project.touch()
        DispatchQueue.main.async {
            // update cache: remove from old list and add to new
            self.projectsByCategory[oldCat]?.removeAll(where: { $0.id == project.id })
            self.projectsByCategory[category.id, default: []].append(project)
            self.objectWillChange.send()
            self.saveProjects()
        }
    }

    func category(with id: UUID?) -> ProjectCategory? {
        guard let id = id else { return nil }
        return categories.first { $0.id == id }
    }

    func moveCategories(from source: IndexSet, to destination: Int) {
        guard categories.count > 1 else { return }
        var filtered = categories
        let fixed = filtered.removeFirst()
        // Adjust source/destination for filtered array (exclude first fixed)
        let adjustedSource = IndexSet(source.map { $0 - 1 })
        let adjustedDestination = max(0, destination - 1)
        filtered.move(fromOffsets: adjustedSource, toOffset: adjustedDestination)
        categories = [fixed] + filtered
        saveCategories()
    }

    private func saveCategories() {
        do {
            let data = try JSONEncoder().encode(categories)
            UserDefaults.standard.set(data, forKey: categoriesKey)
        } catch {
            print("Erreur sauvegarde catégories : \(error)")
        }
    }

    private func loadCategories() {
        guard let data = UserDefaults.standard.data(forKey: categoriesKey) else {
            categories = [ProjectCategory.all]
            return
        }
        do {
            categories = try JSONDecoder().decode([ProjectCategory].self, from: data)
            if categories.isEmpty { categories = [ProjectCategory.all] }
            else {
                if let allIndex = categories.firstIndex(where: { $0.id == ProjectCategory.all.id }) {
                    if allIndex != 0 {
                        let allCategory = categories.remove(at: allIndex)
                        categories.insert(allCategory, at: 0)
                    }
                } else {
                    categories.insert(ProjectCategory.all, at: 0)
                }
            }
        } catch {
            print("Erreur chargement catégories : \(error)")
            categories = [ProjectCategory.all]
        }
    }
    
    // MARK: - Statuses Management
    
    private func loadStatuses() {
        guard let data = UserDefaults.standard.data(forKey: statusesKey) else {
            statuses = ProjectStatus.defaultStatuses
            saveStatuses()
            return
        }
        do {
            statuses = try JSONDecoder().decode([ProjectStatus].self, from: data)
            if statuses.isEmpty {
                statuses = ProjectStatus.defaultStatuses
                saveStatuses()
            }
        } catch {
            print("Erreur chargement statuts : \(error)")
            statuses = ProjectStatus.defaultStatuses
            saveStatuses()
        }
    }
    
    private func saveStatuses() {
        do {
            let data = try JSONEncoder().encode(statuses)
            UserDefaults.standard.set(data, forKey: statusesKey)
        } catch {
            print("Erreur sauvegarde statuts : \(error)")
        }
    }
    
    func addStatus(name: String, colorHex: String) {
        let newOrder = (statuses.map { $0.order }.max() ?? 0) + 1
        let newStatus = ProjectStatus(name: name, colorHex: colorHex, order: newOrder, isSystem: false)
        statuses.append(newStatus)
        statuses.sort { $0.order < $1.order }
        saveStatuses()
    }
    
    func removeStatus(_ status: ProjectStatus) {
        guard !status.isSystem else { return }
        statuses.removeAll { $0.id == status.id }
        
        // Réassigner les projets avec ce statut au statut par défaut
        for project in projects where project.statusID == status.id {
            project.statusID = ProjectStatus.notStarted.id
            project.touch()
        }
        
        saveStatuses()
        saveProjects()
    }
    
    func renameStatus(_ status: ProjectStatus, to newName: String) {
        guard let idx = statuses.firstIndex(where: { $0.id == status.id }) else { return }
        statuses[idx].name = newName
        saveStatuses()
    }
    
    func changeStatusColor(_ status: ProjectStatus, to colorHex: String) {
        guard let idx = statuses.firstIndex(where: { $0.id == status.id }) else { return }
        statuses[idx].colorHex = colorHex
        saveStatuses()
    }
    
    func moveStatuses(from source: IndexSet, to destination: Int) {
        var temp = statuses
        temp.move(fromOffsets: source, toOffset: destination)
        // Recalculer les ordres
        for (index, _) in temp.enumerated() {
            temp[index].order = index
        }
        statuses = temp
        saveStatuses()
    }
    
    func status(with id: UUID?) -> ProjectStatus? {
        guard let id = id else { return nil }
        return statuses.first { $0.id == id }
    }

    func removeProject(_ project: Project, deleteFolderOnDisk: Bool = true) {
        // Supprimer le dossier physique uniquement si demandé
        if deleteFolderOnDisk, let folder = project.rootFolder {
            let didStart = SettingsManager.shared.startAccessingFolder()
            do {
                if FileManager.default.fileExists(atPath: folder.path) {
                    try FileManager.default.removeItem(at: folder)
                    print("✅ Dossier supprimé du disque: \(folder.path)")
                }
            } catch {
                print("❌ Erreur suppression dossier projet: \(error)")
            }
            if didStart { SettingsManager.shared.stopAccessingFolder() }
        } else {
            print("ℹ️ Projet supprimé de l'app uniquement (dossier conservé sur le disque)")
        }

        // Also remove it from in-memory data structures (projects array and per-category cache)
        DispatchQueue.main.async {
            // remove from global list
            if let idx = self.projects.firstIndex(where: { $0.id == project.id }) {
                self.projects.remove(at: idx)
            }

            // determine category key used in cache (if nil, it was stored under .all id)
            let catKey = project.categoryID ?? ProjectCategory.all.id
            // remove from category cache if present
            if var arr = self.projectsByCategory[catKey] {
                arr.removeAll(where: { $0.id == project.id })
                if arr.isEmpty {
                    self.projectsByCategory.removeValue(forKey: catKey)
                } else {
                    self.projectsByCategory[catKey] = arr
                }
            }

            // also ensure the project isn't lingering in the 'all' bucket if it was elsewhere
            if catKey != ProjectCategory.all.id {
                if var allArr = self.projectsByCategory[ProjectCategory.all.id] {
                    allArr.removeAll(where: { $0.id == project.id })
                    if allArr.isEmpty {
                        self.projectsByCategory.removeValue(forKey: ProjectCategory.all.id)
                    } else {
                        self.projectsByCategory[ProjectCategory.all.id] = allArr
                    }
                }
            }

            // clear selection if needed
            if self.selection == project.id { self.selection = nil }
            self.objectWillChange.send()
            self.saveProjects()
        }
    }

    func deleteProject(withId id: UUID, deleteFolderOnDisk: Bool = true) {
        if let proj = projects.first(where: { $0.id == id }) {
            removeProject(proj, deleteFolderOnDisk: deleteFolderOnDisk)
        }
    }
    
    // MARK: - Import/Export
    
    /// Exporte tous les projets vers un fichier
    func exportProjects(to url: URL) throws {
        try PersistenceManager.shared.exportProjects(projects, to: url)
    }
    
    /// Importe des projets depuis un fichier (en fusionnant avec les projets existants)
    func importProjects(from url: URL, merge: Bool = true) throws {
        let importedProjects = try PersistenceManager.shared.importProjects(from: url)
        
        if merge {
            // Fusionner: ajouter uniquement les projets avec des IDs non existants
            let existingIDs = Set(projects.map { $0.id })
            let newProjects = importedProjects.filter { !existingIDs.contains($0.id) }
            
            DispatchQueue.main.async {
                self.projects.append(contentsOf: newProjects)
                self.rebuildProjectsByCategory()
                self.saveProjects()
            }
        } else {
            // Remplacer tous les projets
            DispatchQueue.main.async {
                self.projects = importedProjects
                self.rebuildProjectsByCategory()
                self.saveProjects()
            }
        }
    }
    
    /// Crée la structure de dossiers pour un projet existant
    func createFolderStructure(for project: Project) {
        guard let parent = SettingsManager.shared.projectsFolder else {
            print("❌ Aucun dossier de projets configuré")
            return
        }
        
        let didStart = SettingsManager.shared.startAccessingFolder()
        defer { if didStart { SettingsManager.shared.stopAccessingFolder() } }
        
        do {
            let safeName = FSHelper.sanitizedFolderName(from: project.title)
            let folderURL = try FSHelper.createProjectFolderStructure(root: parent, folderName: safeName)
            
            DispatchQueue.main.async {
                project.rootFolderPath = folderURL.path
                project.hasFolderStructure = true
                project.touch()
                self.saveProjects()
            }
        } catch {
            print("❌ Erreur création structure dossier: \(error)")
        }
    }
    
    /// Scanne le dossier de projets et importe les dossiers qui ont la bonne structure mais ne sont pas répertoriés
    func discoverAndImportExistingProjects() -> Int {
        guard let parent = SettingsManager.shared.projectsFolder else {
            print("❌ Aucun dossier de projets configuré")
            return 0
        }
        
        let didStart = SettingsManager.shared.startAccessingFolder()
        defer { if didStart { SettingsManager.shared.stopAccessingFolder() } }
        
        var importedCount = 0
        
        do {
            // Récupérer tous les dossiers
            let contents = try FileManager.default.contentsOfDirectory(at: parent, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
            
            // Filtrer uniquement les dossiers
            let folders = contents.filter { url in
                var isDir: ObjCBool = false
                return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
            }
            
            // Vérifier quels dossiers ne sont pas déjà dans nos projets
            let existingPaths = Set(projects.compactMap { $0.rootFolderPath })
            
            for folderURL in folders {
                let path = folderURL.path
                
                // Si déjà répertorié, ignorer
                if existingPaths.contains(path) { continue }
                
                // Vérifier si le dossier a la structure attendue
                if hasValidProjectStructure(at: folderURL) {
                    // Créer un nouveau projet
                    let project = Project(
                        title: folderURL.lastPathComponent,
                        rootFolderPath: path,
                        isEditing: false,
                        hasFolderStructure: true
                    )
                    
                    DispatchQueue.main.async {
                        self.projects.append(project)
                        let cat = project.categoryID ?? ProjectCategory.all.id
                        self.projectsByCategory[cat, default: []].append(project)
                    }
                    
                    importedCount += 1
                    print("✅ Projet découvert et importé: \(project.title)")
                }
            }
            
            if importedCount > 0 {
                DispatchQueue.main.async {
                    self.saveProjects()
                }
            }
            
        } catch {
            print("❌ Erreur lors du scan des dossiers: \(error)")
        }
        
        return importedCount
    }
    
    /// Vérifie si un dossier a la structure de projet attendue
    private func hasValidProjectStructure(at url: URL) -> Bool {
        let requiredFolders = [
            "00 IN",
            "01 ASSETS",
            "05 AEP",
            "07 SORTIES"
        ]
        
        // On vérifie qu'au moins quelques dossiers clés existent
        var foundCount = 0
        for folder in requiredFolders {
            let folderURL = url.appendingPathComponent(folder)
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDir) && isDir.boolValue {
                foundCount += 1
            }
        }
        
        // Si on trouve au moins 3 des 4 dossiers clés, on considère que c'est un projet valide
        return foundCount >= 3
    }
}

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

    // Cache to quickly lookup projects per category to avoid repeated filtering
    private var projectsByCategory: [UUID: [Project]] = [:]

    private let categoriesKey = "categories.v1"

    init() {
        loadCategories()
    }

    var filteredProjects: [Project] {
        if selectedCategoryID == ProjectCategory.all.id { return projects }
        return projectsByCategory[selectedCategoryID] ?? []
    }

    func addProject() {
        let newProject = Project()

        // Accès sécurisé au dossier parent
        let didStart = SettingsManager.shared.startAccessingFolder()
        do {
            if let parent = SettingsManager.shared.projectsFolder {
                let safeName = FSHelper.sanitizedFolderName(from: newProject.title)
                let folderURL = try FSHelper.createProjectFolderStructure(root: parent, folderName: safeName)
                newProject.rootFolder = folderURL
                newProject.saveToFolder()
            }
        } catch {
            print("Erreur création dossier projet : \(error)")
        }
        if didStart { SettingsManager.shared.stopAccessingFolder() }

        // Update data structures on main thread
        DispatchQueue.main.async {
            self.projects.append(newProject)
            let cat = newProject.categoryID ?? ProjectCategory.all.id
            self.projectsByCategory[cat, default: []].append(newProject)
            self.selection = newProject.id
        }
    }

    func project(with id: UUID?) -> Project? {
        guard let id else { return nil }
        return projects.first { $0.id == id }
    }

    func scanForExistingProjects(forcePath: URL? = nil) {
        // Run file system scanning on background thread to avoid blocking the UI.
        let folderURL = forcePath ?? SettingsManager.shared.projectsFolder
        guard let parent = folderURL else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            let didStart = SettingsManager.shared.startAccessingFolder()
            var found: [Project] = []
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: parent, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                for url in contents where url.hasDirectoryPath {
                    if let project = Project.fromFolder(url: url) {
                        found.append(project)
                    }
                }
            } catch {
                print("Erreur scan dossier projets : \(error)")
            }
            if didStart { SettingsManager.shared.stopAccessingFolder() }

            DispatchQueue.main.async {
                self.projects = found
                // rebuild mapping cache
                self.projectsByCategory = [:]
                for p in found {
                    let cat = p.categoryID ?? ProjectCategory.all.id
                    self.projectsByCategory[cat, default: []].append(p)
                }
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
            project.saveToFolder()
            // update cache
            DispatchQueue.main.async {
                // remove from old
                self.projectsByCategory[category.id]?.removeAll(where: { $0.id == project.id })
                // add to 'all'
                self.projectsByCategory[ProjectCategory.all.id, default: []].append(project)
            }
        }
        saveCategories()
    }

    func renameCategory(_ category: ProjectCategory, to newName: String) {
        guard let idx = categories.firstIndex(where: { $0.id == category.id }), !categories[idx].isFixed else { return }
        categories[idx].name = newName
        saveCategories()
    }

    func assign(_ project: Project, to category: ProjectCategory) {
        let oldCat = project.categoryID ?? ProjectCategory.all.id
        project.categoryID = category.id
        project.saveToFolder()
        DispatchQueue.main.async {
            // update cache: remove from old list and add to new
            self.projectsByCategory[oldCat]?.removeAll(where: { $0.id == project.id })
            self.projectsByCategory[category.id, default: []].append(project)
            self.objectWillChange.send()
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

    func removeProject(_ project: Project) {
        // Attempt to delete folder contents if present
        if let folder = project.rootFolder {
            let didStart = SettingsManager.shared.startAccessingFolder()
            do {
                if FileManager.default.fileExists(atPath: folder.path) {
                    try FileManager.default.removeItem(at: folder)
                }
            } catch {
                print("Erreur suppression dossier projet: \(error)")
            }
            if didStart { SettingsManager.shared.stopAccessingFolder() }
        }

        DispatchQueue.main.async {
            if let idx = self.projects.firstIndex(where: { $0.id == project.id }) {
                self.projects.remove(at: idx)
            }
            if self.selection == project.id { self.selection = nil }
            self.objectWillChange.send()
        }
    }

    func deleteProject(withId id: UUID) {
        if let proj = projects.first(where: { $0.id == id }) {
            removeProject(proj)
        }
    }
}

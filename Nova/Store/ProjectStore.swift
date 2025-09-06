//
//  ProjectStore.swift
//  Nova
//
//  Created by Maxime Dondon on 25/08/2025.
//

import Foundation

class ProjectStore: ObservableObject {
    @Published var projects: [Project] = []
    @Published var selection: UUID?   // UUID du projet sélectionné

    func addProject() {
        let newProject = Project()
        
        // Accès sécurisé au dossier parent
        SettingsManager.shared.startAccessingFolder()
        defer { SettingsManager.shared.stopAccessingFolder() }
        
        if let parent = SettingsManager.shared.projectsFolder {
            let safeName = FSHelper.sanitizedFolderName(from: newProject.title)
            do {
                let folderURL = try FSHelper.createProjectFolderStructure(root: parent, folderName: safeName)
                newProject.rootFolder = folderURL
                newProject.saveToFolder()
            } catch {
                print("Erreur création dossier projet : \(error)")
            }
        }
        
        projects.append(newProject)
        selection = newProject.id
    }


    func project(with id: UUID?) -> Project? {
        guard let id else { return nil }
        return projects.first { $0.id == id }
    }

    /// Scans the projects folder for existing project directories and adds them to the list
    func scanForExistingProjects(forcePath: URL? = nil) {
        projects.removeAll() // Clear existing projects before scanning
        let folderURL = forcePath ?? SettingsManager.shared.projectsFolder
        guard let parent = folderURL else { return }
        SettingsManager.shared.startAccessingFolder() // Ensure permission
        defer { SettingsManager.shared.stopAccessingFolder() } // Always release
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: parent, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            for url in contents where url.hasDirectoryPath {
                if let project = Project.fromFolder(url: url) {
                    projects.append(project)
                }
            }
        } catch {
            print("Erreur scan dossier projets : \(error)")
        }
    }
}

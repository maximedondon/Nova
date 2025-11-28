//
//  Project.swift
//  Nova
//
//  Created by Maxime Dondon on 25/08/2025.
//

import Foundation
import SwiftUI

enum ProjectTag: String, CaseIterable, Hashable, Identifiable, Codable {
    case deuxD = "2D"
    case troisD = "3D"
    case freelance = "FREELANCE"

    var id: String { rawValue }
}

enum ProjectStatus: String, CaseIterable, Hashable, Identifiable, Codable {
    case notStarted = "Pas commencé"
    case enCours = "En cours"
    case standby = "Stand Bye"
    case finishing = "Finitions"
    case finished = "Terminé"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .notStarted: return .gray
        case .enCours: return .blue
        case .standby: return .orange
        case .finishing: return .purple
        case .finished: return .green
        }
    }
}

class Project: ObservableObject, Identifiable, Codable {
    let id: UUID
    @Published var title: String
    @Published var details: String
    @Published var rootFolder: URL?
    @Published var isEditing: Bool
    @Published var tags: [ProjectTag]
    @Published var status: ProjectStatus
    @Published var categoryID: UUID?
    // whether we've loaded the full project.json into this instance
    @Published var isFullyLoaded: Bool = true

    enum CodingKeys: String, CodingKey {
        case id, title, details, tags, status, categoryID
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.details = try container.decode(String.self, forKey: .details)
        self.tags = try container.decode([ProjectTag].self, forKey: .tags)
        self.status = try container.decode(ProjectStatus.self, forKey: .status)
        self.categoryID = try container.decodeIfPresent(UUID.self, forKey: .categoryID)
        self.rootFolder = nil
        self.isEditing = false
        self.isFullyLoaded = true
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(details, forKey: .details)
        try container.encode(tags, forKey: .tags)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(categoryID, forKey: .categoryID)
    }

    init(
        title: String = "Nouveau projet",
        details: String = "",
        rootFolder: URL? = nil,
        isEditing: Bool = true,
        tags: [ProjectTag] = [],
        status: ProjectStatus = .notStarted,
        id: UUID = UUID()
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.rootFolder = rootFolder
        self.isEditing = isEditing
        self.tags = tags
        self.status = status
        self.categoryID = nil
        self.isFullyLoaded = true
    }

    // MARK: - Raccourcis dossiers

    var aepFolder: URL? {
        rootFolder?.appendingPathComponent("05 AEP")
    }

    var assetsFolder: URL? {
        rootFolder?.appendingPathComponent("01 ASSETS")
    }

    var outputsFolder: URL? {
        rootFolder?.appendingPathComponent("07 SORTIES")
    }

    // Static method to create a Project from a folder URL
    static func fromFolder(url: URL) -> Project? {
        // Read only minimal metadata to keep scanning fast.
        let jsonURL = url.appendingPathComponent("project.json")
        guard FileManager.default.fileExists(atPath: jsonURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: jsonURL)
            let decoder = JSONDecoder()
            struct Meta: Decodable {
                var id: UUID?
                var title: String?
                var status: ProjectStatus?
                var categoryID: UUID?
            }
            let meta = try decoder.decode(Meta.self, from: data)
            let project = Project(
                title: meta.title ?? "Nouveau projet",
                details: "",
                rootFolder: url,
                isEditing: false,
                tags: [],
                status: meta.status ?? .notStarted,
                id: meta.id ?? UUID()
            )
            project.categoryID = meta.categoryID
            project.isFullyLoaded = false
            return project
        } catch {
            print("Erreur chargement project.json: \(error)")
            return nil
        }
    }

    /// Load the full project.json from disk asynchronously and patch self.
    func loadFullFromDisk() {
        guard !isFullyLoaded, let folder = rootFolder else { return }
        let jsonURL = folder.appendingPathComponent("project.json")
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: jsonURL)
                let decoder = JSONDecoder()
                let full = try decoder.decode(Project.self, from: data)
                DispatchQueue.main.async {
                    self.title = full.title
                    self.details = full.details
                    self.tags = full.tags
                    self.status = full.status
                    self.categoryID = full.categoryID
                    self.isFullyLoaded = true
                }
            } catch {
                print("Erreur chargement complet project.json: \(error)")
            }
        }
    }

    func saveToFolder() {
        guard let folder = rootFolder else { return }
        let jsonURL = folder.appendingPathComponent("project.json")
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self)
            try data.write(to: jsonURL)
        } catch {
            print("Erreur sauvegarde project.json: \(error)")
        }
    }
}

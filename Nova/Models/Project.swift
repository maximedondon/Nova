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

// Nouveau système de statuts personnalisables
struct ProjectStatus: Hashable, Identifiable, Codable {
    let id: UUID
    var name: String
    var colorHex: String // Stocké en hex pour la sérialisation
    var order: Int
    var isSystem: Bool // Indique si c'est un statut système (non supprimable)
    
    var color: Color {
        Color(hex: colorHex) ?? .gray
    }
    
    init(id: UUID = UUID(), name: String, colorHex: String, order: Int = 0, isSystem: Bool = false) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.order = order
        self.isSystem = isSystem
    }
    
    // Statuts par défaut
    static let notStarted = ProjectStatus(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "Pas commencé", colorHex: "#808080", order: 0, isSystem: true)
    static let enCours = ProjectStatus(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "En cours", colorHex: "#007AFF", order: 1, isSystem: true)
    static let standby = ProjectStatus(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, name: "Stand By", colorHex: "#FF9500", order: 2, isSystem: true)
    static let finishing = ProjectStatus(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, name: "Finitions", colorHex: "#AF52DE", order: 3, isSystem: true)
    static let finished = ProjectStatus(id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!, name: "Terminé", colorHex: "#34C759", order: 4, isSystem: true)
    
    static let defaultStatuses: [ProjectStatus] = [
        .notStarted, .enCours, .standby, .finishing, .finished
    ]
}

// Extension pour conversion hex -> Color
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (no alpha)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String? {
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

class Project: ObservableObject, Identifiable, Codable {
    let id: UUID
    @Published var title: String
    @Published var details: String
    @Published var notes: String
    @Published var rootFolderPath: String?  // Changé de URL? à String? pour la persistance
    @Published var isEditing: Bool
    @Published var tags: [ProjectTag]
    @Published var statusID: UUID  // ID du statut au lieu de l'objet
    @Published var categoryID: UUID?
    @Published var createdAt: Date
    @Published var updatedAt: Date
    @Published var hasFolderStructure: Bool  // Indique si l'arborescence de dossiers existe
    
    // Computed property pour accéder au dossier racine comme URL
    var rootFolder: URL? {
        guard let path = rootFolderPath else { return nil }
        return URL(fileURLWithPath: path)
    }

    enum CodingKeys: String, CodingKey {
        case id, title, details, notes, tags, statusID, categoryID, rootFolderPath, createdAt, updatedAt, hasFolderStructure
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.details = try container.decode(String.self, forKey: .details)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.tags = try container.decode([ProjectTag].self, forKey: .tags)
        self.statusID = try container.decodeIfPresent(UUID.self, forKey: .statusID) ?? ProjectStatus.notStarted.id
        self.categoryID = try container.decodeIfPresent(UUID.self, forKey: .categoryID)
        self.rootFolderPath = try container.decodeIfPresent(String.self, forKey: .rootFolderPath)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        self.hasFolderStructure = try container.decodeIfPresent(Bool.self, forKey: .hasFolderStructure) ?? false
        self.isEditing = false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(details, forKey: .details)
        try container.encode(notes, forKey: .notes)
        try container.encode(tags, forKey: .tags)
        try container.encode(statusID, forKey: .statusID)
        try container.encodeIfPresent(categoryID, forKey: .categoryID)
        try container.encodeIfPresent(rootFolderPath, forKey: .rootFolderPath)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(hasFolderStructure, forKey: .hasFolderStructure)
    }

    init(
        title: String = "Nouveau projet",
        details: String = "",
        notes: String = "",
        rootFolderPath: String? = nil,
        isEditing: Bool = true,
        tags: [ProjectTag] = [],
        statusID: UUID = ProjectStatus.notStarted.id,
        id: UUID = UUID(),
        hasFolderStructure: Bool = false
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.notes = notes
        self.rootFolderPath = rootFolderPath
        self.isEditing = isEditing
        self.tags = tags
        self.statusID = statusID
        self.categoryID = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.hasFolderStructure = hasFolderStructure
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
    
    // MARK: - Helper Methods
    
    /// Met à jour la date de modification
    func touch() {
        self.updatedAt = Date()
    }
}

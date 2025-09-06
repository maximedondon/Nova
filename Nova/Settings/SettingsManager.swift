//
//  SettingsManager.swift
//  Nova
//
//  Created by Maxime Dondon on 05/09/2025.
//

import Foundation

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    private let bookmarkKey = "projectsFolderBookmark"

    @Published var projectsFolderPublished: URL? = nil

    private var _resolvedURL: URL?
    private var _accessing: Bool = false

    private init() {
        // Charge le bookmark au démarrage
        if let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) {
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
                _resolvedURL = url
                projectsFolderPublished = url
            } catch {
                print("Erreur résolution bookmark: \(error)")
                projectsFolderPublished = nil
            }
        }
    }

    var projectsFolder: URL? {
        // Toujours utiliser l’URL restaurée via le bookmark
        return _resolvedURL
    }

    func setProjectsFolder(_ url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
            var isStale = false
            let resolvedURL = try URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            _resolvedURL = resolvedURL
            projectsFolderPublished = resolvedURL
        } catch {
            print("Erreur création bookmark: \(error)")
            projectsFolderPublished = nil
            _resolvedURL = nil
        }
    }

    func startAccessingFolder() {
        guard let url = _resolvedURL, !_accessing else { return }
        _accessing = url.startAccessingSecurityScopedResource()
    }

    func stopAccessingFolder() {
        guard let url = _resolvedURL, _accessing else { return }
        url.stopAccessingSecurityScopedResource()
        _accessing = false
    }
}


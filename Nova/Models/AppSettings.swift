//
//  AppSettings.swift
//  Nova
//
//  Created by Maxime Dondon on 05/09/2025.
//

import Foundation
import SwiftUI

@MainActor
class AppSettings: ObservableObject {
    @Published var rootFolder: URL? {
        didSet {
            save()
        }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: "rootFolder"),
           let url = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSURL.self, from: data) as URL? {
            self.rootFolder = url
        }
    }

    func pickRootFolder() {
        if let picked = FSHelper.pickDirectory(startingAt: rootFolder) {
            rootFolder = picked
        }
    }

    private func save() {
        if let url = rootFolder {
            let data = try? NSKeyedArchiver.archivedData(withRootObject: url as NSURL, requiringSecureCoding: false)
            UserDefaults.standard.set(data, forKey: "rootFolder")
        } else {
            UserDefaults.standard.removeObject(forKey: "rootFolder")
        }
    }
}

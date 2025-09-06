//
//  NovaApp.swift
//
//  Created by Maxime Dondon on 25/08/2025.
//

import SwiftUI

@main
struct AEPManagerApp: App {
    @StateObject private var store = ProjectStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .windowToolbarStyle(.unified) // apparence moderne
    }
}

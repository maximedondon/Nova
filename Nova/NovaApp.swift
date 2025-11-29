import SwiftUI

@main
struct AEPManagerApp: App {
    @StateObject private var store = ProjectStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }

        Settings {
            PreferencesView()
                .environmentObject(store)
        }
    }
}

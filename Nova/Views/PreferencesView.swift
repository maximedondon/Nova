import SwiftUI

struct PreferencesView: View {
    enum Category: String, CaseIterable, Identifiable {
        case general = "Général"
        case about = "À propos"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .general: return "gear"
            case .about: return "info.circle"
            }
        }
    }

    @State private var selection: Category = .general
    @AppStorage("projectsRootFolderBookmark") private var projectsRootBookmark: Data?
    @State private var chosenFolderPath: String = ""

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            List(selection: $selection) {
                ForEach(Category.allCases) { c in
                    HStack(spacing: 10) {
                        Image(systemName: c.icon)
                            .frame(width: 18, height: 18)
                        Text(c.rawValue)
                    }
                    .padding(.vertical, 4)
                    .tag(c)
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 160, maxWidth: 220)

            Divider()

            // Detail pane
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        content(for: selection)
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 720, height: 460)
        .onAppear { syncFromSettings() }
    }

    @ViewBuilder
    private func content(for category: Category) -> some View {
        switch category {
        case .general:
            general
        case .about:
            about
        }
    }

    // MARK: - UI primitive: SectionCard
    private struct SectionCard<Content: View>: View {
        let title: String?
        let content: Content

        init(title: String? = nil, @ViewBuilder content: () -> Content) {
            self.title = title
            self.content = content()
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                if let t = title { Text(t).font(.subheadline).foregroundStyle(.secondary) }
                VStack(spacing: 0) {
                    content
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Sections
    private var general: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Réglages généraux").padding(.leading)

            SectionCard {
                HStack(spacing: 8) {
                    VStack(alignment: .leading) {
                        Text("Emplacement des projets")
                        Text(chosenFolderPath.isEmpty ? "Non défini" : chosenFolderPath)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: 520, alignment: .leading)
                    }
                    Spacer()
                    Button {
                        pickFolder()
                    } label: {
                        Label("Choisir…", systemImage: "folder")
                    }
                }
            }

            Spacer()
        }
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("À propos").padding(.leading)

            SectionCard {
                VStack(alignment: .leading, spacing: 12) {
                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
                    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Version")
                            Text("\(version) (\(build))").foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    Divider()

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Crédits")
                            Text("© 2025 Maxime Dondon").foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    Divider()

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Support et journaux")
                            Text("Ouvre le dossier contenant les journaux de l'application.").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            openLogsFolder()
                        } label: {
                            Label("Ouvrir les logs", systemImage: "doc.text.magnifyingglass")
                        }
                    }
                }
            }

            Spacer()
        }
    }

    private func syncFromSettings() {
        if let url = SettingsManager.shared.projectsFolder {
            chosenFolderPath = url.path()
        } else {
            chosenFolderPath = ""
        }
    }

    private func pickFolder() {
        if let url = FSHelper.pickDirectory(startingAt: SettingsManager.shared.projectsFolder) {
            SettingsManager.shared.setProjectsFolder(url)
            syncFromSettings()
        }
    }

    // MARK: - Advanced actions
    private func resetPreferences() {
        let defaults = UserDefaults.standard
        // Remove known keys (bookmark and any app-specific keys)
        defaults.removeObject(forKey: "projectsFolderBookmark")
        defaults.synchronize()
        // Reflect in SettingsManager
        SettingsManager.shared.setProjectsFolder(URL?.none!)
    }

    private func clearCaches() {
        // Placeholder: implement cache directory cleanup if you have one
    }

    private func exportPreferences() {
        // Placeholder: serialize needed preferences to JSON and save via NSSavePanel
    }

    private func importPreferences() {
        // Placeholder: open NSOpenPanel, read JSON, apply settings and refresh UI
    }

    private func openLogsFolder() {
        // Placeholder: if you maintain a logs directory, open it here
        // FSHelper.open(logsURL)
    }
}

#Preview {
    PreferencesView()
}

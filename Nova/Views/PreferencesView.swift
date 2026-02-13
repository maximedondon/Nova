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
    @EnvironmentObject var store: ProjectStore
    @ObservedObject var settings = SettingsManager.shared
    @State private var showImportSuccess: Bool = false
    @State private var importedCount: Int = 0
    @State private var showExportSuccess: Bool = false
    @State private var showImportError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showDiscoverSuccess: Bool = false
    @State private var discoveredCount: Int = 0

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
        .alert("Import réussi", isPresented: $showImportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(importedCount) projet(s) importé(s) avec succès.")
        }
        .alert("Export réussi", isPresented: $showExportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Les projets ont été exportés avec succès.")
        }
        .alert("Erreur", isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Découverte terminée", isPresented: $showDiscoverSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            if discoveredCount > 0 {
                Text("\(discoveredCount) projet(s) découvert(s) et importé(s).")
            } else {
                Text("Aucun nouveau projet trouvé.")
            }
        }
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

            SectionCard(title: "Dossiers de projets") {
                VStack(spacing: 12) {
                    // Liste des dossiers
                    ForEach(settings.projectFolders) { folder in
                        HStack(spacing: 12) {
                            // Icône dossier
                            Image(systemName: "folder.fill")
                                .foregroundStyle(folder.isDefault ? .blue : .secondary)
                            
                            // Nom et chemin
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(folder.name)
                                        .font(.system(size: 13, weight: folder.isDefault ? .semibold : .regular))
                                    if folder.isDefault {
                                        Text("Par défaut")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }
                                }
                                if let url = folder.url {
                                    Text(url.path)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                } else {
                                    Text("Dossier inaccessible")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                            
                            Spacer()
                            
                            // Actions
                            if !folder.isDefault && settings.projectFolders.count > 1 {
                                Button {
                                    settings.setAsDefault(folder)
                                } label: {
                                    Text("Définir par défaut")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.blue)
                            }
                            
                            if settings.projectFolders.count > 1 {
                                Button {
                                    settings.removeFolder(folder)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.red)
                                .help("Supprimer ce dossier")
                            }
                        }
                        .padding(.vertical, 4)
                        
                        if folder.id != settings.projectFolders.last?.id {
                            Divider()
                        }
                    }
                    
                    // Bouton ajouter
                    Divider()
                    Button {
                        addNewFolder()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Ajouter un dossier")
                        }
                        .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            SectionCard(title: "Gestion des données") {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Découvrir des projets existants")
                            Text("Scanner le dossier de projets pour importer des dossiers non répertoriés").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            discoverExistingProjects()
                        } label: {
                            Label("Scanner", systemImage: "magnifyingglass")
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Exporter les projets")
                            Text("Sauvegarder tous vos projets dans un fichier JSON").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            exportPreferences()
                        } label: {
                            Label("Exporter", systemImage: "square.and.arrow.up")
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Importer des projets")
                            Text("Fusionner des projets depuis un fichier JSON").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            importPreferences()
                        } label: {
                            Label("Importer", systemImage: "square.and.arrow.down")
                        }
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
                            Text("Dossier de données")
                            Text("Ouvre le dossier contenant les données de l'application.").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            openDataFolder()
                        } label: {
                            Label("Ouvrir", systemImage: "folder")
                        }
                    }
                }
            }

            Spacer()
        }
    }

    private func syncFromSettings() {
        chosenFolderPath = SettingsManager.shared.projectsFolder?.path ?? ""
    }

    private func addNewFolder() {
        if let url = FSHelper.pickDirectory(startingAt: SettingsManager.shared.projectsFolder) {
            do {
                try SettingsManager.shared.addFolder(url, name: url.lastPathComponent, setAsDefault: false)
            } catch {
                errorMessage = "Impossible d'ajouter le dossier: \(error.localizedDescription)"
                showImportError = true
            }
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
        let panel = NSSavePanel()
        panel.message = "Exporter les projets"
        panel.nameFieldStringValue = "Nova-Projects-\(dateString()).json"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        
        guard panel.runModal() == .OK, let url = panel.url else { return }
        
        do {
            try store.exportProjects(to: url)
            showExportSuccess = true
        } catch {
            errorMessage = "Impossible d'exporter les projets: \(error.localizedDescription)"
            showImportError = true
        }
    }

    private func importPreferences() {
        let panel = NSOpenPanel()
        panel.message = "Importer des projets"
        panel.prompt = "Importer"
        panel.allowedContentTypes = [.json]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        guard panel.runModal() == .OK, let url = panel.url else { return }
        
        do {
            let beforeCount = store.projects.count
            try store.importProjects(from: url, merge: true)
            let afterCount = store.projects.count
            importedCount = afterCount - beforeCount
            showImportSuccess = true
        } catch {
            errorMessage = "Impossible d'importer les projets: \(error.localizedDescription)"
            showImportError = true
        }
    }
    
    private func discoverExistingProjects() {
        discoveredCount = store.discoverAndImportExistingProjects()
        showDiscoverSuccess = true
    }
    
    private func dateString() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }

    private func openDataFolder() {
        if let folder = PersistenceManager.shared.getPersistenceFolder() {
            FSHelper.open(folder)
        }
    }
}

#Preview {
    PreferencesView()
        .environmentObject(ProjectStore())
}

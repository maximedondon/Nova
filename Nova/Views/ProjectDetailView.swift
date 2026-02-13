//
//  ProjectDetailView.swift
//  Nova
//
//  Created by Maxime Dondon on 25/08/2025.
//

import SwiftUI

struct ProjectDetailView: View {
    @ObservedObject var project: Project
    @EnvironmentObject var store: ProjectStore

    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAEConfirm: Bool = false
    @State private var showCreateFolderConfirm: Bool = false
    @State private var showStatusManager: Bool = false
    @FocusState private var titleFocused: Bool

    // Notes locale pour édition en continu
    @State private var notesDraft: String = ""
    @State private var notesSaveWorkItem: DispatchWorkItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header avec titre et actions
                titleHeader
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                
                Divider()
                    .padding(.horizontal, 24)
                
                // Tags (si présents et pas en édition)
                if !project.isEditing && !project.tags.isEmpty {
                    tagDisplay
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                }
                
                // Contenu principal
                VStack(alignment: .leading, spacing: 20) {
                    // Section Statut
                    statusSection
                    
                    // Section Tags (en mode édition)
                    if project.isEditing {
                        tagsSection
                    }
                    
                    // Section Actions (si pas en édition et si dossier existe)
                    if !project.isEditing {
                        actionsSection
                    }
                    
                    // Section Notes
                    notesSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onChange(of: project.isEditing) { _, newValue in
            if newValue {
                DispatchQueue.main.async { titleFocused = true }
            } else {
                titleFocused = false
            }
        }
        .alert(alertTitle, isPresented: $showAlert, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(alertMessage)
        })
        .confirmationDialog(
            "Aucun fichier .aep trouvé. Voulez-vous ouvrir After Effects ?",
            isPresented: $showAEConfirm,
            titleVisibility: .visible
        ) {
            Button("Oui") { openAfterEffects() }
            Button("Non", role: .cancel) {}
        }
        .confirmationDialog(
            "Créer la structure de dossiers pour ce projet ?",
            isPresented: $showCreateFolderConfirm,
            titleVisibility: .visible
        ) {
            Button("Créer") {
                store.createFolderStructure(for: project)
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Cela créera l'arborescence complète de dossiers pour ce projet.")
        }
        .sheet(isPresented: $showStatusManager) {
            StatusManagerView()
                .environmentObject(store)
        }
    }

    // MARK: - Header Title

    private var titleHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            // Titre
            TextField("Nouveau projet", text: $project.title)
                .font(.system(size: 28, weight: .bold))
                .textFieldStyle(.plain)
                .focused($titleFocused)
                .allowsHitTesting(project.isEditing)
                .onSubmit {
                    if project.isEditing {
                        save()
                    }
                }
                .onKeyPress(.escape) {
                    if project.isEditing {
                        cancelEditing()
                        return .handled
                    }
                    return .ignored
                }
                .contextMenu {
                    if !project.isEditing {
                        Button {
                            project.isEditing = true
                        } label: {
                            Label("Renommer", systemImage: "pencil")
                        }
                    }
                }
            
            Spacer()

            // Actions à droite
            HStack(spacing: 10) {
                // Bouton pour créer l'arborescence si elle n'existe pas
                if !project.hasFolderStructure {
                    Button(action: { showCreateFolderConfirm = true }) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 18))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Créer la structure de dossiers")
                } else if project.rootFolder != nil {
                    // Bouton pour ouvrir le dossier seulement si l'arbo existe
                    Button(action: { openProjectFolder() }) {
                        Image(systemName: "folder")
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Ouvrir le dossier du projet")
                }

                if project.isEditing {
                    Divider()
                        .frame(height: 20)

                    Button(action: { save() }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.blue)
                    }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .buttonStyle(.plain)
                    .help("Sauvegarder (⌘↩)")

                    Button(action: { cancelEditing() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Annuler (Esc)")
                }
            }
        }
    }

    // MARK: - Tags affichage lecture

    private var tagDisplay: some View {
        HStack(spacing: 8) {
            ForEach(project.tags, id: \.self) { tag in
                Text(tag.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Section Statut

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Statut")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button {
                    showStatusManager = true
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Gérer les statuts")
            }
            
            Picker("", selection: Binding(
                get: { project.statusID },
                set: { newStatusID in
                    project.statusID = newStatusID
                    project.touch()
                    store.saveProjects()
                })
            ) {
                ForEach(store.statuses) { status in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(status.color)
                            .frame(width: 8, height: 8)
                        Text(status.name)
                    }
                    .tag(status.id)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.gray.opacity(0.06))
        )
    }
    
    // MARK: - Section Tags (édition)
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
            
            Menu {
                ForEach(ProjectTag.allCases) { tag in
                    Button {
                        toggleTag(tag)
                    } label: {
                        HStack {
                            Text(tag.rawValue)
                            if project.tags.contains(tag) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(project.tags.isEmpty ? "Aucun tag sélectionné" : project.tags.map { $0.rawValue }.joined(separator: ", "))
                        .font(.system(size: 13))
                        .foregroundStyle(project.tags.isEmpty ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.1))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.gray.opacity(0.06))
        )
    }
    
    // MARK: - Section Actions
    
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions Rapides")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
            
            VStack(spacing: 10) {
                // After Effects
                Button {
                    openLatestAEP()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.blue)
                            .frame(width: 32, alignment: .center)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Projet After Effects")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                            Text("Ouvrir le dernier .aep")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.01))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(project.rootFolder == nil)
                .opacity(project.rootFolder == nil ? 0.5 : 1)
                
                Divider()
                    .padding(.leading, 44)
                
                // Assets
                Button {
                    openAssets()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 20))
                            .foregroundStyle(.purple)
                            .frame(width: 32, alignment: .center)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dossier Assets")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                            Text("Ressources et médias")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.01))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(project.rootFolder == nil)
                .opacity(project.rootFolder == nil ? 0.5 : 1)
                
                Divider()
                    .padding(.leading, 44)
                
                // Sorties
                Button {
                    openOutputs()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.green)
                            .frame(width: 32, alignment: .center)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dossier Sorties")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                            Text("Rendus et exports")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.01))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(project.rootFolder == nil)
                .opacity(project.rootFolder == nil ? 0.5 : 1)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.gray.opacity(0.06))
        )
    }
    
    // MARK: - Section Notes
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notes")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("Sauvegarde automatique")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            TextEditor(text: $notesDraft)
                .font(.system(size: 13))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 200, maxHeight: 400)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.gray.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.gray.opacity(0.15), lineWidth: 1)
                )
                .onChange(of: notesDraft) { _, newValue in
                    notesSaveWorkItem?.cancel()
                    let workItem = DispatchWorkItem { [weak project] in
                        guard let project = project else { return }
                        DispatchQueue.main.async {
                            project.notes = newValue
                            project.touch()
                            self.store.saveProjects()
                        }
                    }
                    notesSaveWorkItem = workItem
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.8, execute: workItem)
                }
                .onAppear {
                    notesDraft = project.notes
                }
        }
    }

    // MARK: - Actions logiques

    private func openProjectFolder() {
        _ = SettingsManager.shared.startAccessingFolder()
        defer { SettingsManager.shared.stopAccessingFolder() }
        guard let root = project.rootFolder, FSHelper.exists(at: root) else {
            show("Dossier introuvable", "Impossible d'ouvrir le dossier du projet.")
            return
        }
        FSHelper.open(root)
    }

    private func openLatestAEP() {
        _ = SettingsManager.shared.startAccessingFolder()
        defer { SettingsManager.shared.stopAccessingFolder() }
        guard let aepFolder = project.aepFolder, FSHelper.exists(at: aepFolder) else {
            show("Dossier AEP introuvable", "Le dossier “06 AEP” est introuvable sous le dossier du projet.")
            return
        }
        guard let url = FSHelper.latestAEP(in: aepFolder) else {
            showAEConfirm = true
            return
        }
        FSHelper.open(url)
    }

    private func openAssets() {
        _ = SettingsManager.shared.startAccessingFolder()
        defer { SettingsManager.shared.stopAccessingFolder() }
        guard let folder = project.assetsFolder, FSHelper.exists(at: folder) else {
            show("Dossier introuvable", "Impossible d'ouvrir les assets.")
            return
        }
        FSHelper.open(folder)
    }

    private func openOutputs() {
        _ = SettingsManager.shared.startAccessingFolder()
        defer { SettingsManager.shared.stopAccessingFolder() }
        guard let folder = project.outputsFolder, FSHelper.exists(at: folder) else {
            show("Dossier introuvable", "Impossible d'ouvrir les sorties.")
            return
        }
        FSHelper.open(folder)
    }

    private func openAfterEffects() {
        let aeURL = URL(fileURLWithPath: "/Applications/Adobe After Effects 2025/Adobe After Effects 2025.app")
        if FSHelper.exists(at: aeURL) {
            FSHelper.open(aeURL)
        } else {
            show("After Effects introuvable", "Impossible de trouver l'application After Effects dans /Applications.")
        }
    }

    private func save() {
        guard !project.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            show("Titre manquant", "Veuillez saisir un titre.")
            return
        }
        
        // Si le projet a une structure de dossiers, gérer le renommage
        if project.hasFolderStructure {
            guard let root = SettingsManager.shared.projectsFolder else {
                show("Dossier racine manquant", "Veuillez paramétrer le dossier de projets dans les réglages.")
                return
            }
            _ = SettingsManager.shared.startAccessingFolder()
            defer { SettingsManager.shared.stopAccessingFolder() }
            guard FSHelper.exists(at: root) else {
                show("Dossier racine inaccessible", "Le dossier de projets n'existe pas ou n'est pas accessible.")
                return
            }
            do {
                let newName = FSHelper.sanitizedFolderName(from: project.title)
                if let oldFolder = project.rootFolder, oldFolder.lastPathComponent != newName {
                    let newFolder = try FSHelper.renameFolder(at: oldFolder, to: newName)
                    project.rootFolderPath = newFolder.path
                }
            } catch {
                show("Erreur dossier projet", "Impossible de renommer le dossier : \(error.localizedDescription)")
                return
            }
        }
        
        project.touch()
        store.saveProjects()
        project.isEditing = false
    }

    private func cancelEditing() {
        project.isEditing = false
    }

    private func toggleTag(_ tag: ProjectTag) {
        if project.tags.contains(tag) {
            project.tags.removeAll { $0 == tag }
        } else {
            project.tags.append(tag)
        }
    }

    private func show(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

#Preview {
    ProjectDetailView(project: Project(
        title: "Spot TV",
        rootFolderPath: "/Users/moi/Documents/SpotTV",
        isEditing: true,
        tags: [.troisD, .freelance],
        statusID: ProjectStatus.enCours.id,
        hasFolderStructure: true
    ))
    .environmentObject(ProjectStore())
}

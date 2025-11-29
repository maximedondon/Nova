//
//  ProjectDetailView.swift
//  Nova
//
//  Created by Maxime Dondon on 25/08/2025.
//

import SwiftUI

struct ProjectDetailView: View {
    @ObservedObject var project: Project

    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAEConfirm: Bool = false
    @FocusState private var titleFocused: Bool

    // Notes locale pour édition en continu
    @State private var notesDraft: String = ""
    @State private var notesSaveWorkItem: DispatchWorkItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                titleHeader
                Divider()
                if !project.isEditing && !project.tags.isEmpty {
                    tagDisplay
                }
                if !project.isEditing {
                    actionSection
                }
                statusPicker
                if project.isEditing {
                    editForm
                } else {
                    viewForm
                }

                // --- Zone de notes (toujours éditable) ---
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Notes")
                            .padding(.leading, 10)
                        Spacer()
                        if project.rootFolder != nil {
                            Text("Enregistré automatiquement")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.trailing, 10)
                        }
                    }
                    
                    
                    VStack(alignment: .leading) {
                        
                        TextEditor(text: $notesDraft)
                            .padding(12)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 200, maxHeight: 400)
                            .onChange(of: notesDraft) { _, newValue in
                                // Cancel any pending save
                                notesSaveWorkItem?.cancel()
                                let workItem = DispatchWorkItem { [weak project] in
                                    guard let project = project else { return }
                                    DispatchQueue.main.async {
                                        project.notes = newValue
                                        project.saveToFolder()
                                    }
                                }
                                notesSaveWorkItem = workItem
                                DispatchQueue.global().asyncAfter(deadline: .now() + 0.8, execute: workItem)
                            }
                            .onAppear {
                                notesDraft = project.notes
                            }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.gray.opacity(0.1))
                    )
                }
                .padding(.top, 6)

            }
            .padding(20)
        }
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
    }

    // MARK: - Header Title

    private var titleHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Nouveau projet", text: $project.title)
                    .font(.largeTitle.bold())
                    .textFieldStyle(.plain)
                    .focused($titleFocused)
                    .allowsHitTesting(project.isEditing)
                    .opacity(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 4)

            // Actions déplacées ici (à droite du titre)
            HStack(spacing: 8) {
                if project.rootFolder != nil {
                    Button(action: { openProjectFolder() }) {
                        Image(systemName: "folder")
                    }
                    .buttonStyle(.plain)
                    .help("Ouvrir le dossier du projet")
                }
                

                if project.isEditing {
                    Divider()

                    Button(action: { save() }) {
                        Image(systemName: "checkmark.circle")
                    }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .buttonStyle(.plain)
                    .help("Sauvegarder")

                    Button(action: { cancelEditing() }) {
                        Image(systemName: "xmark.circle")
                    }
                    .buttonStyle(.plain)
                    .help("Annuler")
                }
                // Editing is handled from the toolbar; do not show the pencil here.
            }
            .font(.title2)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 100, style: .continuous)
                    .fill(Color.gray.opacity(0.1))
            )
        }
    }

    // MARK: - Tags affichage lecture

    private var tagDisplay: some View {
        HStack {
            ForEach(project.tags, id: \.self) { tag in
                Text(tag.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    // MARK: - Statut Picker

    private var statusPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack (alignment: .leading, spacing: 4) {
                Text("Suivi de projet")
            }.padding(.leading, 10)
            HStack {
                Text("Statut")
                Spacer()
                Picker("", selection: Binding(
                    get: { project.status },
                    set: { newStatus in
                        project.status = newStatus
                        project.saveToFolder()
                    })
                ) {
                    ForEach(ProjectStatus.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .pickerStyle(.menu)
                .fixedSize()
            }.padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.gray.opacity(0.1))
            )
        }
    }

    // MARK: - Lecture (vue clean)

    private var viewForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Ajoute ici les infos en lecture seule si besoin
        }
    }

    // MARK: - Edition (Description + choix dossier + multi-select tags)

    private var editForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            LabeledContent("Tags") {
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
                        Text(project.tags.isEmpty ? "Aucun" : project.tags.map { $0.rawValue }.joined(separator: ", "))
                        Image(systemName: "chevron.down")
                            .foregroundStyle(.secondary)
                    }
                    .padding(6)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .frame(maxWidth: 180, alignment: .leading)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.gray.opacity(0.1))
        )
    }

    // MARK: - Actions (AEP, Assets, Sorties)

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack (alignment: .leading, spacing: 4) {
                Text("Actions")
            }.padding(.leading, 10)
            VStack(alignment: .leading) {
                LabeledContent("Projet After Effects") {
                    Spacer()
                    Button {
                        openLatestAEP()
                    } label: {
                        Label("Ouvrir", systemImage: "externaldrive")
                    }
                    .disabled(project.rootFolder == nil)
                }
                Divider()
                LabeledContent("Dossiers") {
                    Spacer()
                    Button {
                        openAssets()
                    } label: {
                        Label("Assets", systemImage: "folder")
                    }
                    .disabled(project.rootFolder == nil)

                    Button {
                        openOutputs()
                    } label: {
                        Label("Sorties", systemImage: "folder")
                    }
                    .disabled(project.rootFolder == nil)
                }
            }.padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.gray.opacity(0.1))
            )
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
            if let oldFolder = project.rootFolder, oldFolder.lastPathComponent != FSHelper.sanitizedFolderName(from: project.title) {
                project.rootFolder = try FSHelper.renameFolder(at: oldFolder, to: FSHelper.sanitizedFolderName(from: project.title))
            } else if project.rootFolder == nil {
                project.rootFolder = try FSHelper.createProjectFolderStructure(root: root, folderName: FSHelper.sanitizedFolderName(from: project.title))
            }
        } catch {
            show("Erreur dossier projet", "Impossible de créer ou renommer le dossier : \(error.localizedDescription)")
            return
        }
        project.saveToFolder()
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
        rootFolder: URL(fileURLWithPath: "/Users/moi/Documents/SpotTV"),
        isEditing: true,
        tags: [.troisD, .freelance],
        status: .enCours
    ))
}

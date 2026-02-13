//
//  CreateProjectView.swift
//  Nova
//
//  Dialog pour créer un nouveau projet avec choix du dossier
//

import SwiftUI

struct CreateProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: ProjectStore
    
    @State private var selectedFolderID: UUID?
    @State private var createStructure: Bool = false
    
    var onProjectCreated: (UUID) -> Void
    
    // Calculer la hauteur dynamique
    private var dynamicHeight: CGFloat {
        let baseHeight: CGFloat = 400  // Header + toggle + boutons (augmenté de 300 à 400)
        let folderHeight: CGFloat = 75  // Hauteur par dossier (augmenté de 70 à 75)
        let foldersCount = CGFloat(SettingsManager.shared.projectFolders.count)
        let contentHeight = baseHeight + (foldersCount * folderHeight)
        return min(contentHeight, 750)  // Maximum 750px (augmenté de 700 à 750)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 52))
                    .foregroundStyle(.blue)
                
                Text("Nouveau Projet")
                    .font(.title2.bold())
                
                Text("Choisissez où créer votre projet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)
            
            Divider()
            
            // Contenu principal
            VStack(alignment: .leading, spacing: 0) {
                // Section Emplacement
                VStack(alignment: .leading, spacing: 16) {
                    Text("Emplacement")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            // Dossier par défaut
                            if let defaultFolder = SettingsManager.shared.defaultFolder {
                                FolderOptionButton(
                                    folder: defaultFolder,
                                    isSelected: selectedFolderID == defaultFolder.id,
                                    isDefault: true
                                ) {
                                    selectedFolderID = defaultFolder.id
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Autres dossiers
                            ForEach(SettingsManager.shared.projectFolders.filter { !$0.isDefault }) { folder in
                                FolderOptionButton(
                                    folder: folder,
                                    isSelected: selectedFolderID == folder.id,
                                    isDefault: false
                                ) {
                                    selectedFolderID = folder.id
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 16)
                    }
                    .frame(maxHeight: 320)
                }
                
                Divider()
                
                // Section Options
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Créer la structure de dossiers")
                                .font(.system(size: 13))
                            Text("00 IN, 01 ASSETS, 05 AEP, etc.")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $createStructure)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
                
                Divider()
            }
            
            // Footer avec boutons
            HStack(spacing: 12) {
                Spacer()
                
                Button("Annuler") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Créer") {
                    createProject()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(selectedFolderID == nil)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .frame(width: 540, height: dynamicHeight)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            // Sélectionner le dossier par défaut au démarrage
            selectedFolderID = SettingsManager.shared.defaultFolder?.id
        }
    }
    
    private func createProject() {
        // Récupérer le dossier sélectionné
        guard let folderID = selectedFolderID,
              let targetFolder = SettingsManager.shared.folder(with: folderID) else {
            print("❌ Aucun dossier sélectionné")
            return
        }
        
        print("📁 Création du projet dans: \(targetFolder.name)")
        
        // Créer le projet dans le dossier choisi
        store.addProject(createFolderStructure: createStructure, in: targetFolder)
        
        // Notifier le parent et fermer
        if let newId = store.selection {
            onProjectCreated(newId)
        }
        dismiss()
    }
}

// Bouton pour sélectionner un dossier
struct FolderOptionButton: View {
    let folder: ProjectFolder
    let isSelected: Bool
    let isDefault: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? .blue : .secondary)
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(folder.name)
                            .font(.system(size: 13))
                        
                        if isDefault {
                            Text("Par défaut")
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .foregroundColor(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }
                    
                    if let url = folder.url {
                        Text(url.path)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text("Dossier inaccessible")
                            .font(.system(size: 11))
                            .foregroundStyle(.red)
                    }
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CreateProjectView { _ in }
        .environmentObject(ProjectStore())
}

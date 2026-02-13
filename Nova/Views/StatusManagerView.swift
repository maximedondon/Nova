//
//  StatusManagerView.swift
//  Nova
//
//  Gestionnaire de statuts personnalisables
//

import SwiftUI

struct StatusManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: ProjectStore
    
    @State private var editingStatusID: UUID?
    @State private var editingText: String = ""
    @State private var showingColorPicker: UUID?
    @State private var pickerColor: Color = .blue
    @FocusState private var focusedStatusID: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Gérer les statuts")
                    .font(.title2.bold())
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Liste des statuts
            List {
                Section {
                    ForEach(store.statuses) { status in
                        StatusRow(
                            status: status,
                            editingStatusID: $editingStatusID,
                            editingText: $editingText,
                            focusedStatusID: $focusedStatusID,
                            showingColorPicker: $showingColorPicker,
                            pickerColor: $pickerColor
                        )
                    }
                    .onMove { source, destination in
                        store.moveStatuses(from: source, to: destination)
                    }
                } header: {
                    Text("Faites glisser pour réorganiser")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Bouton ajouter
                Button {
                    addNewStatus()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Nouveau statut")
                    }
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.inset)
        }
        .frame(width: 500, height: 400)
    }
    
    private func addNewStatus() {
        let colors = ["#007AFF", "#34C759", "#FF9500", "#FF3B30", "#AF52DE", "#5856D6"]
        let randomColor = colors.randomElement() ?? "#007AFF"
        store.addStatus(name: "Nouveau statut", colorHex: randomColor)
        
        // Entrer en mode édition automatiquement
        if let newStatus = store.statuses.last {
            editingStatusID = newStatus.id
            editingText = newStatus.name
            focusedStatusID = newStatus.id
        }
    }
}

struct StatusRow: View {
    let status: ProjectStatus
    @Binding var editingStatusID: UUID?
    @Binding var editingText: String
    @FocusState.Binding var focusedStatusID: UUID?
    @Binding var showingColorPicker: UUID?
    @Binding var pickerColor: Color
    @EnvironmentObject var store: ProjectStore
    
    private func commitRename() {
        let newName = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !newName.isEmpty, newName != status.name {
            store.renameStatus(status, to: newName)
        }
        editingStatusID = nil
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Couleur
            Button {
                pickerColor = status.color
                showingColorPicker = status.id
            } label: {
                Circle()
                    .fill(status.color)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help("Changer la couleur")
            .popover(isPresented: Binding(
                get: { showingColorPicker == status.id },
                set: { if !$0 { showingColorPicker = nil } }
            )) {
                VStack(spacing: 16) {
                    ColorPicker("Couleur", selection: $pickerColor, supportsOpacity: false)
                        .labelsHidden()
                        .padding()
                    
                    Button("Valider") {
                        if let hex = pickerColor.toHex() {
                            store.changeStatusColor(status, to: hex)
                        }
                        showingColorPicker = nil
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom)
                }
                .frame(width: 250, height: 200)
            }
            
            // Nom
            if editingStatusID == status.id {
                TextField("Nom du statut", text: $editingText)
                    .textFieldStyle(.plain)
                    .focused($focusedStatusID, equals: status.id)
                    .onAppear {
                        editingText = status.name
                        focusedStatusID = status.id
                    }
                    .onSubmit { commitRename() }
                    .onChange(of: focusedStatusID) { _, new in
                        if new != status.id && editingStatusID == status.id {
                            commitRename()
                        }
                    }
            } else {
                Text(status.name)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            
            // Indicateur système
            if status.isSystem {
                Text("Système")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            if !status.isSystem {
                Button {
                    editingStatusID = status.id
                    focusedStatusID = status.id
                } label: {
                    Label("Renommer", systemImage: "pencil")
                }
                
                Divider()
                
                Button(role: .destructive) {
                    store.removeStatus(status)
                } label: {
                    Label("Supprimer", systemImage: "trash")
                }
            }
        }
    }
}

#Preview {
    StatusManagerView()
        .environmentObject(ProjectStore())
}

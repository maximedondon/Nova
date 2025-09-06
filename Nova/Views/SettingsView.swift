//
//  SettingsView.swift
//  Nova
//
//  Created by Maxime Dondon on 05/09/2025.
//

import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @State private var folder: URL?
    @EnvironmentObject var store: ProjectStore

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .center, spacing: 10) {
                Image(systemName: "gearshape")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(.blue)
                
                VStack(spacing: 10) {
                    Text("Paramètres")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text("Gérez vos préférences et configurations.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center ) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Stockage des projets")
                            Text(folder?.path ?? SettingsManager.shared.projectsFolder?.path ?? "Aucun dossier choisi")
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundStyle(.secondary)

                        }
                        Spacer()
                        Button("Changer") {
                            folder = FSHelper.pickDirectory()
                        }
                }
                Divider()
                VStack(alignment: .leading, spacing: 5) {
                    Text("Version 1.0.0")
                        .foregroundStyle(.secondary)
                    Text("© 2025 Maxime Dondon")
                        .foregroundStyle(.secondary)
                }
            }.padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.windowBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .padding(.horizontal)

           

            Spacer()

            Button("Enregistrer") {
                if let folder = folder {
                    SettingsManager.shared.setProjectsFolder(folder)
                    store.scanForExistingProjects()
                }
                isPresented = false
            }
            .disabled(folder == nil)
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
        .onAppear {
            folder = SettingsManager.shared.projectsFolder
        }
    }
}

#Preview {
    SettingsView(isPresented: .constant(true))
}

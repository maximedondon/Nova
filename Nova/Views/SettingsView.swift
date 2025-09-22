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

    var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "Version \(version) (\(build))"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .center, spacing: 20) {
                Image(systemName: "gearshape")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(.blue)
                
                VStack(spacing: 5) {
                    Text("Paramètres")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text("Gérez vos préférences et configurations.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center ) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Stockage des projets")
                            Text(folder?.path ?? SettingsManager.shared.projectsFolder?.path ?? "Aucun dossier choisi")
                                .lineLimit(1)
                                .font(.caption)
                                .truncationMode(.middle)
                                .foregroundStyle(.secondary)

                        }
                        Spacer()
                        Button("Changer") {
                            folder = FSHelper.pickDirectory()
                        }
                }
                Divider()
                VStack(alignment: .leading) {
                    Text(appVersionString)
                        .foregroundStyle(.secondary)
                    Text("© 2025 Maxime Dondon")
                        .foregroundStyle(.secondary)
                }

                    
            }.padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.background)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .padding(.horizontal)

           

            Spacer()
            
            OnboardingButton(
                title: "Enregistrer et fermer",
                isPrimary: false,
                disabled: folder == nil
            ) {
                if let folder = folder {
                    SettingsManager.shared.setProjectsFolder(folder)
                    store.scanForExistingProjects()
                }
                isPresented = false
            }
        }
        .padding()
        .onAppear {
            folder = SettingsManager.shared.projectsFolder
        }
    }
}

#Preview {
    SettingsView(isPresented: .constant(true))
}

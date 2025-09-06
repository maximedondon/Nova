//
//  OnboardingView.swift
//  Nova
//
//  Created by Maxime Dondon on 05/09/2025.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var selectedFolder: URL?
    @EnvironmentObject var store: ProjectStore

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.gearshape")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundStyle(.blue)
            
            VStack(spacing: 10) {
                Text("Bienvenue dans une gestion de projet plus sûre.")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text("Choisissez où vous voulez stocker vos projets. Vous pourrez toujours modifier ce dossier plus tard dans les paramètres.")
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                selectedFolder = FSHelper.pickDirectory()
            }) {
                Text(selectedFolder?.path() ?? "Choisir un dossier…")
                    .lineLimit(1)
                   .truncationMode(.middle)
            }

            Spacer()

            Button("Terminer") {
                guard let folder = selectedFolder else { return }
                SettingsManager.shared.setProjectsFolder(folder)
                store.scanForExistingProjects()
                isPresented = false
            }
            .disabled(selectedFolder == nil)
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}

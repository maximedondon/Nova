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
        VStack {
            Spacer()
            VStack(spacing: 40) {
                VStack(spacing: 10){
                    let appIcon = NSApplication.shared.applicationIconImage ?? NSImage(size: NSSize(width: 64, height: 64))
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)

                    VStack(spacing: 5) {
                        Text("Commencer avec Nova")
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                        Text("Choisissez où vous voulez stocker vos projets. Vous pourrez toujours modifier ce dossier plus tard dans les réglages.")
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 350)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                FolderDropZone(selectedFolder: $selectedFolder) {
                    selectedFolder = FSHelper.pickDirectory()
                }

                OnboardingButton(
                    title: "Terminer",
                    isPrimary: true,
                    disabled: selectedFolder == nil
                ) {
                    guard let folder = selectedFolder else { return }
                    SettingsManager.shared.setProjectsFolder(folder)
                    store.syncWithProjectsFolder()
                    isPresented = false
                }
            }
            Spacer()
        }
        .padding()

    }
}


#Preview {
    OnboardingView(isPresented: .constant(true))
}

//
//  ContentView.swift
//  Nova
//
//  Created by Maxime Dondon on 25/08/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ProjectStore
    @State private var showOnboarding: Bool = false
    @State private var showSettings: Bool = false

    var body: some View {
        NavigationSplitView {
            Sidebar(isSettingsPresented: $showSettings)
                .navigationTitle("Projets")
        } detail: {
            if let project = store.project(with: store.selection) {
                ProjectDetailView(project: project)
            } else {
                PlaceholderDetail()
            }
        }
        .onAppear {
            if SettingsManager.shared.projectsFolder == nil {
                showOnboarding = true
            } else {
                /// showOnboarding = true
                store.scanForExistingProjects()
            }
        }
        .onChange(of: SettingsManager.shared.projectsFolderPublished) {
            store.scanForExistingProjects()
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(isPresented: $showSettings)
        }
    }
}

// MARK: - Sidebar
struct Sidebar: View {
    @EnvironmentObject var store: ProjectStore
    @State private var showDeleteAlert: Bool = false
    @State private var projectToDelete: Project?
    @Binding var isSettingsPresented: Bool

    var body: some View {
        List(selection: $store.selection) {
            ForEach(Array(store.projects.enumerated()), id: \.element.id) { index, project in
                VStack(alignment: .leading, spacing: 10) {
                    NavigationLink(value: project.id) {
                        SidebarRow(project: project)
                    }
                    .tag(project.id)
                    .contextMenu {
                        Button(role: .destructive) {
                            projectToDelete = project
                            showDeleteAlert = true
                        } label: {
                            Label("Supprimer", systemImage: "trash")
                        }
                    }
                    Divider()
                }
            }
        }
        .toolbar {
            HStack {
                Button {
                    store.addProject()
                } label: {
                    Label("Ajouter un projet", systemImage: "plus")
                }

                Button {
                    isSettingsPresented.toggle()
                } label: {
                    Label("Paramètres", systemImage: "gearshape")
                }
            }
        }
        .alert("Supprimer le projet ?", isPresented: $showDeleteAlert, actions: {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer") {
                if let project = projectToDelete {
                    deleteProject(project, removeFiles: true) // ou false selon la logique
                }
            }
        }, message: {
            Text("Voulez-vous supprimer le projet et ses fichiers associés ?")
        })
    }

    private func deleteProject(_ project: Project, removeFiles: Bool) {
        if removeFiles, let root = project.rootFolder {
            try? FileManager.default.removeItem(at: root)
        }
        if let index = store.projects.firstIndex(where: { $0.id == project.id }) {
            store.projects.remove(at: index)
            if store.selection == project.id {
                store.selection = nil
            }
        }
    }
}

// MARK: - SidebarRow
struct SidebarRow: View {
    @ObservedObject var project: Project

    var body: some View {
        VStack(alignment: .leading) {
            Text(project.title)
            HStack(spacing: 6) {
                Text(project.status.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(project.status.color.opacity(0.2))
                    .foregroundColor(project.status.color)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}

// MARK: - Placeholder
struct PlaceholderDetail: View {
    var body: some View {
        ContentUnavailableView {
            Label("Aucun projet selectionné", systemImage: "tray.fill")
        } description: {
            Text("Selectionnez en un ou créez-en un nouveau.")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ProjectStore())
}

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var store: ProjectStore
    @State private var showOnboarding: Bool = false
    @State private var showSettings: Bool = false

    @State private var editingCategoryID: UUID? = nil
    @State private var editingText: String = ""
    @State private var localSelectedCategoryID: UUID? = nil
    @State private var localSelection: UUID? = nil
    @FocusState private var focusedCategoryID: UUID?
    @State private var showDeleteConfirm: Bool = false
    @State private var projectToDelete: UUID? = nil

    var body: some View {
        NavigationSplitView {
            categoriesSidebar
        } content: {
            projectsList
        } detail: {
            detailView
        }
        .onAppear {
            if SettingsManager.shared.projectsFolder == nil {
                showOnboarding = true
            } else {
                store.scanForExistingProjects()
                localSelectedCategoryID = store.selectedCategoryID
                localSelection = store.selection
            }
        }
        .onChange(of: localSelectedCategoryID) { _, new in
            if let v = new {
                store.selectedCategoryID = v
            } else {
                store.selectedCategoryID = ProjectCategory.all.id
            }
        }
        .onChange(of: localSelection) { _, new in
            store.selection = new
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(isPresented: $showSettings)
                .environmentObject(store)
        }
        .onChange(of: store.selectedCategoryID) { _, new in
            localSelectedCategoryID = new
        }
        .alert("Supprimer le projet?", isPresented: $showDeleteConfirm, actions: {
            Button("Supprimer", role: .destructive) {
                if let id = projectToDelete {
                    store.deleteProject(withId: id)
                    projectToDelete = nil
                }
            }
            Button("Annuler", role: .cancel) {
                projectToDelete = nil
            }
        }, message: {
            Text("Cette action supprimera le dossier du projet et toutes ses données. Êtes-vous sûr(e) ?")
        })
    }

    // MARK: - Sidebar: Categories
    private var categoriesSidebar: some View {
        List(selection: $localSelectedCategoryID) {
            Section("Catégories") {
                ForEach(store.categories, id: \.id) { category in
                    CategoryRow(
                        category: category,
                        editingCategoryID: $editingCategoryID,
                        editingText: $editingText,
                        focusedCategory: $focusedCategoryID
                    )
                    .environmentObject(store)
                }

                Divider()

                Button {
                    let new = store.addCategory()
                    // Enter edit mode immediately for new category
                    editingCategoryID = new.id
                    editingText = new.name
                    localSelectedCategoryID = new.id
                    focusedCategoryID = new.id
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                        Text("Nouveau")
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        // Constrain the sidebar width so it doesn't expand and hide the detail view on launch
        .frame(minWidth: 160, idealWidth: 220, maxWidth: 300)
    }

    // MARK: - Content: Projects
    private var projectsList: some View {
        List(selection: $localSelection) {
            ForEach(store.filteredProjects) { project in
                NavigationLink(value: project.id) {
                    // resolve category info once and pass it to the row to avoid lookups in the row's body
                    let cat = store.category(with: project.categoryID)
                    SidebarRow(id: project.id, title: project.title, status: project.status, categoryName: cat?.name, categoryImage: cat?.systemImage, onSelect: { id in
                        // Selecting via tap anywhere on the row — disable implicit animation
                        localSelection = id
                        withTransaction(Transaction(animation: nil)) {
                            store.selection = id
                        }
                    })
                    .contextMenu {
                        Button(role: .destructive) {
                            projectToDelete = project.id
                            showDeleteConfirm = true
                        } label: {
                            Label("Supprimer", systemImage: "trash")
                        }
                    }
                }
                .tag(project.id)
            }
        }
        .frame(minWidth: 260, idealWidth: 340, maxWidth: 420)
        // Keep the projects list from taking over the detail column; detail gets its own min width below
        .toolbar {
            HStack {
                Button {
                    store.addProject()
                } label: {
                    Label("Ajouter un projet", systemImage: "plus")
                }

                Button {
                    showSettings.toggle()
                } label: {
                    Label("Paramètres", systemImage: "gearshape")
                }
            }
        }
    }

    // MARK: - Detail
    private var detailView: some View {
        Group {
            if let project = store.project(with: store.selection) {
                ProjectDetailView(project: project)
                    .task {
                        if !project.isFullyLoaded {
                            project.loadFullFromDisk()
                        }
                    }
            } else {
                PlaceholderDetail()
            }
        }
        // Ensure detail area keeps a usable minimum width so the middle column (projects) can't cover it
        .frame(minWidth: 360)
    }
}

// MARK: - SidebarRow
struct SidebarRow: View {
    let id: UUID
    let title: String
    let status: ProjectStatus
    let categoryName: String?
    let categoryImage: String?
    var onSelect: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            // Make the title a plain button so taps are recognized immediately (no gesture disambiguation delay)
            Button(action: { onSelect(id) }) {
                Text(title)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            HStack(spacing: 6) {
                Text(status.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(status.color.opacity(0.2))
                    .foregroundColor(status.color)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            if let cname = categoryName, let image = categoryImage {
                Label(cname, systemImage: image)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        // Use onTapGesture for selection to avoid gesture-disambiguation delay (tap vs drag)
        .onTapGesture { onSelect(id) }
        .onDrag { NSItemProvider(object: id.uuidString as NSString) }
    }
}

// MARK: - CategoryRow
struct CategoryRow: View {
    let category: ProjectCategory
    @Binding var editingCategoryID: UUID?
    @Binding var editingText: String
    var focusedCategory: FocusState<UUID?>.Binding
    @EnvironmentObject var store: ProjectStore

    private func commitRename() {
        let newName = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !newName.isEmpty, newName != category.name {
            store.renameCategory(category, to: newName)
        }
        editingCategoryID = nil
    }

    var body: some View {
        HStack {
            Image(systemName: category.systemImage)
            if editingCategoryID == category.id && !category.isFixed {
                TextField("Nom de la catégorie", text: $editingText)
                    .textFieldStyle(.plain)
                    .focused(focusedCategory, equals: category.id)
                    .onAppear {
                        editingText = category.name
                        focusedCategory.wrappedValue = category.id
                    }
                    .onSubmit { commitRename() }
                    .onChange(of: focusedCategory.wrappedValue) { _, new in
                        if new != category.id && editingCategoryID == category.id {
                            commitRename()
                        }
                    }
            } else {
                HStack(spacing: 8) {
                    Button(action: {
                        // immediate selection without waiting for gesture disambiguation
                        store.selectedCategoryID = category.id
                    }) {
                        Text(category.name)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)

                }
            }
        }
        .contentShape(Rectangle())
        .tag(category.id)
        .contextMenu {
            if !category.isFixed {
                Button() {
                    editingCategoryID = category.id
                    focusedCategory.wrappedValue = category.id
                } label: {
                    Label("Renommer", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    store.removeCategory(category)
                } label: {
                    Label("Supprimer", systemImage: "trash")
                }
            }
        }
        .onDrag { NSItemProvider(object: category.id.uuidString as NSString) }
        .onDrop(of: [UTType.text], isTargeted: nil) { providers in
            guard let provider = providers.first else { return false }
            provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
                var str: String?
                if let data = item as? Data { str = String(data: data, encoding: .utf8) }
                if let s = item as? String { str = s }
                guard let s = str else { return }

                // Category reorder
                if let catUUID = UUID(uuidString: s),
                   let sourceIndex = store.categories.firstIndex(where: { $0.id == catUUID }),
                   let destIndex = store.categories.firstIndex(where: { $0.id == category.id }) {
                    if sourceIndex != 0 && destIndex != 0 {
                        DispatchQueue.main.async {
                            let to = destIndex > sourceIndex ? destIndex + 1 : destIndex
                            store.moveCategories(from: IndexSet(integer: sourceIndex), to: to)
                        }
                        return
                    }
                }

                // Project drop -> assign
                if let projUUID = UUID(uuidString: s), let proj = store.project(with: projUUID) {
                    DispatchQueue.main.async {
                        if let destCat = store.category(with: category.id) {
                            store.assign(proj, to: destCat)
                        }
                    }
                }
            }
            return true
        }
    }
}

// MARK: - Placeholder
struct PlaceholderDetail: View {
    var body: some View {
        ContentUnavailableView {
            Label("Aucun projet sélectionné", systemImage: "tray.fill")
        } description: {
            Text("Sélectionnez-en un ou créez-en un nouveau.")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ProjectStore())
}

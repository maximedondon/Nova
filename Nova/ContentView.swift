import SwiftUI
import AppKit
import UniformTypeIdentifiers

// Removed accidental @main App wrapper from this file. App entry is in NovaApp.swift.

struct ContentView: View {
    @EnvironmentObject var store: ProjectStore
    @Environment(\.openWindow) private var openWindow
    @State private var showOnboarding: Bool = false

    @State private var editingCategoryID: UUID? = nil
    @State private var editingText: String = ""
    @State private var localSelectedCategoryID: UUID? = nil
    @State private var localSelection: UUID? = nil
    @FocusState private var focusedCategoryID: UUID?
    @State private var showDeleteConfirm: Bool = false
    @State private var projectToDelete: UUID? = nil

    // Search state in toolbar
    @State private var searchText: String = ""

    var body: some View {
        NavigationSplitView {
            categoriesSidebar
        } content: {
            projectsList
        } detail: {
            detailView
        }
        .searchable(text: $searchText, placement: .toolbar)
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
        .toolbar {
            // Action buttons as separate toolbar items to ensure visibility
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    store.addProject()
                    // After store sets the selection, start editing the new project
                    DispatchQueue.main.async {
                        if let newId = store.selection {
                            startEditingProject(newId)
                        }
                    }
                }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .help("Nouveau projet")
                .keyboardShortcut("n", modifiers: .command)
                .padding(.horizontal, 12)
            }

            ToolbarItem(placement: .automatic) {
                Button(action: {
                    if let sel = store.selection {
                        startEditingProject(sel)
                    }
                }) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)
                .help("Modifier le projet sélectionné")
                .disabled(store.selection == nil)
                .keyboardShortcut("e", modifiers: .command)
                .padding(.horizontal, 12)
            }
        }
    }

    // MARK: - Sidebar: Categories
    private var categoriesSidebar: some View {
        List(selection: $localSelectedCategoryID) {
            Section("Catégories") {
                ForEach(store.categories, id: \.id) { category in
                    CategoryRow(category: category,
                                editingCategoryID: $editingCategoryID,
                                editingText: $editingText,
                                focusedCategory: $focusedCategoryID,
                                selectedCategoryID: $localSelectedCategoryID)
                        .environmentObject(store)
                }

                Divider()

                Button {
                    let new = store.addCategory()
                    // Enter edit mode immediately
                    editingCategoryID = new.id
                    editingText = new.name
                    localSelectedCategoryID = new.id
                    focusedCategoryID = new.id
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                        Text("Nouveau")
                    }
                    .padding(.vertical, 0)
                    .padding(.horizontal, 6)
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 160, idealWidth: 220, maxWidth: 300)
    }

    // MARK: - Content: Projects
    private var projectsList: some View {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let visibleProjects = store.filteredProjects.filter { project in
            guard !query.isEmpty else { return true }
            return project.title.localizedCaseInsensitiveContains(query)
        }

        return List(selection: $localSelection) {
            ForEach(visibleProjects, id: \.id) { project in
                NavigationLink(value: project.id) {
                    let cat = store.category(with: project.categoryID)
                    SidebarRow(project: project, categoryName: cat?.name, categoryImage: cat?.systemImage, onSelect: { id in
                        localSelection = id
                        withTransaction(Transaction(animation: nil)) { store.selection = id }
                    })
                    .contextMenu {
                        Button(role: .destructive) {
                            projectToDelete = project.id
                            showDeleteConfirm = true
                        } label: { Label("Supprimer", systemImage: "trash") }
                    }
                }
                .tag(project.id)
                .padding(.vertical, 6)
                .padding(.horizontal, 6)
            }
        }
        .frame(minWidth: 260, idealWidth: 340, maxWidth: 420)
    }

    // MARK: - Detail
    private var detailView: some View {
        Group {
            if let project = store.project(with: store.selection) {
                ProjectDetailView(project: project)
                    .task {
                        if !project.isFullyLoaded { project.loadFullFromDisk() }
                    }
            } else {
                PlaceholderDetail()
            }
        }
        .frame(minWidth: 360)
    }
}

// MARK: - SidebarRow
struct SidebarRow: View {
    @ObservedObject var project: Project
    let categoryName: String?
    let categoryImage: String?
    var onSelect: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: { onSelect(project.id) }) {
                Text(project.title)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            HStack(spacing: 6) {
                Text(project.status.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(project.status.color.opacity(0.2))
                    .foregroundColor(project.status.color)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            if let cname = categoryName, let image = categoryImage {
                Label(cname, systemImage: image)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onSelect(project.id) }
        .onDrag { NSItemProvider(object: project.id.uuidString as NSString) }
    }
}

// MARK: - CategoryRow
struct CategoryRow: View {
    let category: ProjectCategory
    @Binding var editingCategoryID: UUID?
    @Binding var editingText: String
    var focusedCategory: FocusState<UUID?>.Binding
    @Binding var selectedCategoryID: UUID?
    @EnvironmentObject var store: ProjectStore

    private func commitRename() {
        let newName = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !newName.isEmpty, newName != category.name {
            store.renameCategory(category, to: newName)
        }
        editingCategoryID = nil
    }

    var body: some View {
        Group {
            if editingCategoryID == category.id && !category.isFixed {
                HStack {
                    Image(systemName: category.systemImage)
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
                }
            } else {
                HStack {
                    Image(systemName: category.systemImage)
                    Text(category.name)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if editingCategoryID != category.id {
                        selectedCategoryID = category.id
                        store.selectedCategoryID = category.id
                    }
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
                } label: { Label("Renommer", systemImage: "pencil") }
                Button(role: .destructive) {
                    store.removeCategory(category)
                } label: { Label("Supprimer", systemImage: "trash") }
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

// Helper: select a project and open it in edit mode. Selecting first ensures the detail view exists to receive focus.
extension ContentView {
    fileprivate func startEditingProject(_ id: UUID) {
        // Set local selection which will be propagated to store.selection via onChange
        localSelection = id
        // Enable editing slightly later to allow the detail to mount
        DispatchQueue.main.async {
            if let proj = store.project(with: id) {
                proj.isEditing = true
            }
        }
    }
}

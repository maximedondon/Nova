//
//  FolderDropZone.swift
//  Nova
//
//  Created by Maxime Dondon on 07/09/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct FolderDropZone: View {
    @Binding var selectedFolder: URL?
    var onPick: (() -> Void)?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    selectedFolder == nil ? Color.accentColor : Color.green,
                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.background)
                )
                .frame(height: 80)

            HStack() {
                Image(systemName: "folder")
                    .font(.system(size: 24))
                    .foregroundColor(Color.gray)
                VStack(alignment: .leading) {
                    if let folder = selectedFolder {
                        Text(folder.lastPathComponent)
                        Text(folder.path())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text("Glissez un dossier ici ou cliquez pour choisir")
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal)
        }
        .onTapGesture {
            onPick?()
        }
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: nil) { providers in
            if let item = providers.first {
                item.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
                    guard let data = data as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil),
                          url.hasDirectoryPath
                    else { return }
                    DispatchQueue.main.async {
                        selectedFolder = url
                    }
                }
                return true
            }
            return false
        }
        .animation(.default, value: selectedFolder)
    }
}

#Preview {
    FolderDropZone(selectedFolder: .constant(nil))
}

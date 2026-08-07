import SwiftUI

struct LibraryInfoItem: View {
    var title: LocalizedStringKey
    var info: String
    
    var body: some View {
        HStack {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(info)
                .foregroundStyle(.secondary)
        }
    }
}

struct LibraryInfoPanel: View {
    @Environment(\.dismiss) var dismiss
    var library: Library
    
    var body: some View {
        NavigationStack {
            List {
                Section("Statistics") {
                    if let db = library.db {
                        LibraryInfoItem(title: "Database Version", info: String(db.databaseVersion))
                    }
                    LibraryInfoItem(title: "Entries", info: String(library.entries.count))
                    LibraryInfoItem(title: "Tags", info: String(library.tags.count))
                    if let fieldTemplates = library.fieldTemplates {
                        LibraryInfoItem(title: "Field Templates", info: String(fieldTemplates.count))
                    }
                    LibraryInfoItem(title: "Colors", info: String(library.tagColors.colors.count))
                    LibraryInfoItem(title: "Namespaces", info: String(library.tagColors.namespaces.count))
                }
            }
            .navigationTitle("Library Info")
            .modifier(NavigationSubtitleCompat(subtitle: "for \(library.getName())"))
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseButton(dismiss: dismiss)
                }
            }
        }
    }
}

private struct NavigationSubtitleCompat: ViewModifier {
    let subtitle: String

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.navigationSubtitle(subtitle)
        } else {
            content
        }
    }
}

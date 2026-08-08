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

struct LibraryFixIgnoredButton: View {
    var body: some View {
        Button {
            
        } label: {
            Label("Fix Ignored", systemImage: "minus.circle.fill")
                .frame(maxWidth: .infinity)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .buttonStyle(.bordered)
        .tint(.orange)
    }
}

struct LibraryFixUnlinkedButton: View {
    var body: some View {
        Button {
            
        } label: {
            Label("Fix Unlinked", systemImage: "link")
                .frame(maxWidth: .infinity)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .buttonStyle(.bordered)
        .tint(.red)
    }
}

struct LibraryFixDuplicateButton: View {
    var body: some View {
        Button {
            
        } label: {
            Label("Fix Duplicates", systemImage: "document.on.document")
                .frame(maxWidth: .infinity)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .buttonStyle(.bordered)
        .tint(.blue)
    }
}

struct LibraryFixAllButton: View {
    var body: some View {
        Button {
            
        } label: {
            Label("Fix All", systemImage: "ellipsis")
                .frame(maxWidth: .infinity)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .buttonStyle(.bordered)
        .tint(.gray)
    }
}

struct LibraryInfoPanel: View {
    @Environment(\.dismiss) var dismiss
    @ScaledMetric(relativeTo: .body) private var minColumnWidth: CGFloat = 150
    var library: Library
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ListLikeSection("Statistics")
                    VStack {
                        if let db = library.db {
                            LibraryInfoItem(title: "Database Version", info: String(db.databaseVersion))
                            Divider()
                        }
                        LibraryInfoItem(title: "Entries", info: String(library.entries.count))
                        Divider()
                        LibraryInfoItem(title: "Tags", info: String(library.tags.count))
                        Divider()
                        if let fieldTemplates = library.fieldTemplates {
                            LibraryInfoItem(title: "Field Templates", info: String(fieldTemplates.count))
                            Divider()
                        }
                        LibraryInfoItem(title: "Colors", info: String(library.tagColors.colors.count))
                        Divider()
                        LibraryInfoItem(title: "Namespaces", info: String(library.tagColors.namespaces.count))
                    }
                    .padding()
                    .background(.background.quaternary, in: LWConcentricRectangle())
                    ListLikeSection("Clean Up")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: minColumnWidth))]
                    ) {
                        LibraryFixIgnoredButton()
                        LibraryFixUnlinkedButton()
                        LibraryFixDuplicateButton()
                        LibraryFixAllButton()
                    }
                }
                .padding()
            }
            .navigationTitle("Library Info")
            .modifier(NavigationSubtitleCompat(subtitle: "for \(library.getName())"))
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton(dismiss: dismiss)
                }
            }
            .containerShape(.rect(cornerRadius: 40))
        }
        .background(.background.secondary)
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

import SwiftUI

struct LibraryInfoItem<LabelContents: View>: View {
    let label: LabelContents
    var info: String
    
    init(
        info: String,
        @ViewBuilder label: @escaping () -> LabelContents
    ) {
        self.info = info
        self.label = label()
    }
    
    init(
        info: Int,
        @ViewBuilder label: @escaping () -> LabelContents
    ) {
        self.info = String(info)
        self.label = label()
    }
    
    var body: some View {
        
        HStack {
            label
                .frame(maxWidth: .infinity, alignment: .leading)
                .labelStyle(.uniformIconWidth)
            Text(info)
                .foregroundStyle(.secondary)
        }
    }
}

struct UniformIconLabelStyle: LabelStyle {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    var iconWidth: CGFloat = 24

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            if dynamicTypeSize < .xxxLarge {
                configuration.icon
                    .frame(width: iconWidth, alignment: .center)
            }
            
            configuration.title
        }
    }
}

extension LabelStyle where Self == UniformIconLabelStyle {
    static var uniformIconWidth: UniformIconLabelStyle { UniformIconLabelStyle() }
    
    static func uniformIconWidth(_ width: CGFloat) -> UniformIconLabelStyle {
        UniformIconLabelStyle(iconWidth: width)
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
                            LibraryInfoItem(info: db.databaseVersion) {
                                Label("Database Version", systemImage: "cylinder.split.1x2")
                            }
                            Divider()
                        }
                        LibraryInfoItem(info: library.entries.count) {
                            Label("Entries", systemImage: "photo.fill")
                        }
                        Divider()
                        LibraryInfoItem(info: library.tags.count) {
                            Label("Tags", systemImage: "tag")
                        }
                        Divider()
                        if let fieldTemplates = library.fieldTemplates {
                            LibraryInfoItem(info: fieldTemplates.count) {
                                Label("Field Templates", systemImage: "character.textbox")
                            }
                            Divider()
                        }
                        LibraryInfoItem(info: library.tagColors.colors.count) {
                            Label("Colors", systemImage: "paintpalette")
                        }
                        Divider()
                        LibraryInfoItem(info: library.tagColors.namespaces.count) {
                            Label("Namespaces", systemImage: "rainbow")
                        }
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

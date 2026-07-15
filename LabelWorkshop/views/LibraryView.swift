import SwiftUI

enum LibraryZoom: CGFloat {
    case LargeEntries = 120
    case MediumEntries = 70
}

struct LibraryView: View {
    let library: Library
    @State var entries: [Entry]
    
    @State private var showTagManager: Bool = false
    @State var showTagfilter: Bool = false
    @State var searchQuery: String = ""
    @State var tagFilters: [Tag] = []
    @State var shownEntries: [Entry]
    @State var zoom: LibraryZoom = .LargeEntries
    @State var tags: [Tag] = []
    @State var migrationClosed: Bool = false
    
    @Environment(\.openURL) private var openURL
    
    private let tagFilterTip = TagFilterTip()
    
    init(library: Library) {
        self.library = library
        self.entries = library.safeGetEntries(limit: 30)
        self.tags = self.library.tags.all
        self.shownEntries = library.safeGetEntries()
        self.updateEntries()
    }
    
    func updateEntries() {
        let allEntries = library.safeGetEntries()
        if searchQuery == "" && self.tagFilters.isEmpty {
            self.shownEntries = allEntries
            return
        }
        var updatedEntriesList: [Entry] = []
        
        for entry in allEntries {
            var qualifiesSearch = true
            if searchQuery != "" {
                qualifiesSearch = entry.path.lowercased().contains(searchQuery.lowercased())
            }
            if qualifiesSearch && entry.tags.containsAll(tagFilters)  {
                updatedEntriesList.append(entry)
            }
        }
        self.shownEntries = updatedEntriesList
    }
    
    func getViewGrid(_ geometry: GeometryProxy) -> [GridItem] {
        let entriesInRow = (geometry.size.width / CGFloat(self.zoom.rawValue)).rounded(.down)
        return Array(repeating: GridItem(.flexible()), count: Int(entriesInRow))
    }
    
    func addTagToFilter(_ tag: Tag) {
        if tagFilters.contains(where: { filterTag in
            return filterTag.id == tag.id
        }) {
            tagFilters.removeAll(where: { filterTag in
                return filterTag.id == tag.id
            })
        } else {
            tagFilters.append(tag)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                if self.library.migrationState != .MigrationNotRequired && !self.migrationClosed {
                    MigrationProgress(library: library, closed: $migrationClosed)
                }
                LazyVGrid(columns: getViewGrid(geometry)) {
                    ForEach(shownEntries, id: \.path) { entry in
                        GridRow {
                            EntryMiniView(entry: entry)
                        }
                    }
                }.padding(16)
            }
        }
        .toolbar {
            ToolbarItem( placement: .navigationBarTrailing){
                Menu {
                    Button(action: {
                        showTagManager = true
                    }) {
                        Label("Tag Manager", systemImage: "tag")
                    }
                    Button(action: {
                        if self.zoom == .LargeEntries {
                            self.zoom = .MediumEntries
                        } else {
                            self.zoom = .LargeEntries
                        }
                    }) {
                        Label(self.zoom == .LargeEntries ? "Zoom Out" : "Zoom In", systemImage: self.zoom == .LargeEntries ? "minus.magnifyingglass" : "plus.magnifyingglass")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
            ToolbarItem(placement: .bottomBar) {
                Button(action: {
                    showTagfilter = true
                    tagFilterTip.invalidate(reason: .actionPerformed)
                }) {
                    Image(systemName: "tag")
                }
                .tint(tagFilters.isEmpty ? .primary : .blue)
                .popoverTip(tagFilterTip, arrowEdge: .bottom)
                .sheet(isPresented: $showTagfilter) {
                    TagSearch(library: self.library, tags: $tags, selectAction: addTagToFilter, multiSelect: true, selected: self.tagFilters, closeButton: true)
                        .onAppear {
                            self.library.tags.refresh()
                            self.tags = self.library.tags.all
                        }
                }
            }
        }
        .sheet(isPresented: $showTagManager) {
            TagManagerView(library: library)
        }
        .navigationTitle(library.getName())
        .task {
            do {
                try await library.migrate()
            } catch {print(error)}
            self.entries = library.safeGetEntries()
        }
        .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always))
        .searchPresentationToolbarBehavior(.avoidHidingContent)
        .onChange(of: tagFilters) {
            self.updateEntries()
        }
        .onChange(of: searchQuery) {
            self.updateEntries()
        }
    }
}


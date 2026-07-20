import SwiftUI

enum LibraryZoom: CGFloat {
    case LargeEntries = 120
    case MediumEntries = 70
}

struct LibraryCommands: Commands {
    @Bindable var appState: AppState
    
    var body: some Commands {
        CommandMenu("Library") {
            Button("Tag Manager", systemImage: "tag") {
                appState.showTagManager = true
            }
            .keyboardShortcut(KeyboardShortcut("M", modifiers: [.command, .shift]))
        }
    }
}

struct LibraryView: View {
    let library: Library
    @State var entries: [Entry]
    @State var showTagfilter: Bool = false
    @State var searchQuery: String = ""
    @State var tagFilters: [Tag] = []
    @State var shownEntries: [Entry]
    @State var zoom: LibraryZoom = .LargeEntries
    @State var namesShown: Bool = true
    @State var tags: [Tag] = []
    @State var migrationClosed: Bool = false
    @State var hiddenShown: Bool = false
    
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL
    
    private let tagFilterTip = TagFilterTip()
    
    private let namedPadding: EdgeInsets = EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
    private let unnamedPadding: EdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    
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
        return Array(repeating: GridItem(.flexible(), spacing: namesShown ? 8 : 1), count: Int(entriesInRow))
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
    
    func isEntryHidden(_ entry: Entry) -> Bool {
        if hiddenShown {return false}
        else if !entry.tags.isHidden {return false}
        return true
    }
    
    var body: some View {
        @Bindable var appState = appState
        GeometryReader { geometry in
            ScrollView {
                if self.library.migrationState != .MigrationNotRequired && !self.migrationClosed {
                    MigrationProgress(library: library, closed: $migrationClosed)
                }
                LazyVGrid(columns: getViewGrid(geometry), spacing: namesShown ? 8 : 1) {
                    ForEach(shownEntries, id: \.path) { entry in
                        if !isEntryHidden(entry) {
                            GridRow {
                                EntryMiniView(entry: entry, namesShown: $namesShown)
                            }
                        }
                    }
                }.padding(namesShown ? namedPadding : unnamedPadding)
            }
        }
        .toolbar {
            ToolbarItem( placement: .navigationBarTrailing){
                Menu {
                    Button(action: {
                        appState.showTagManager = true
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
                    Button(action: {
                        self.namesShown.toggle()
                    }) {
                        Label(self.namesShown ? "Hide Names" : "Show Names", systemImage: "textformat")
                    }
                    Button(action: {
                        self.hiddenShown.toggle()
                    }) {
                        Label(self.hiddenShown ? "Hide Hidden Entries" : "Show Hidden Entries", systemImage: self.hiddenShown ? "eye.slash" : "eye")
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
        .sheet(isPresented: $appState.showTagManager) {
            TagManagerView(library: library)
        }
        .navigationTitle(library.getName())
        .task {
            do {
                try library.addNewEntries()
            } catch {print(error)}
            self.entries = library.safeGetEntries()
            updateEntries()
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


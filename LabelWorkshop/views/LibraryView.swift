import SwiftUI

enum LibraryGridZoom: CGFloat {
    case Large = 120
    case Medium = 70
}

enum LibraryListZoom: CGFloat {
    case Large = 50
    case Medium = 30
}

enum LibraryZoom: CGFloat {
    case Large
    case Medium
}

enum LibraryViewType {
    case Grid
    case List
    case Masonry
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
    @State var tags: [Tag] = []
    
    // Sheets
    @State var showTagfilter: Bool = false
    @State var migrationClosed: Bool = false
    
    // Filtering
    @State var searchQuery: String = ""
    @State var tagFilters: [Tag] = []
    
    // View Options
    @State var zoom: LibraryZoom = .Large
    @State var namesShown: Bool = true
    @State var hiddenShown: Bool = false
    @State var filterUntagged: Bool = false
    @State var viewType: LibraryViewType = .Grid
    
    @Environment(AppState.self) private var appState
    
    let LIST_VIEW_SIZES: [LibraryZoom: CGFloat] = [.Large: 50, .Medium: 30]
    let GRID_VIEW_SIZES: [LibraryZoom: CGFloat] = [.Large: 120, .Medium: 70]
    
    private let tagFilterTip = TagFilterTip()
    
    private let namedPadding: EdgeInsets = EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
    private let unnamedPadding: EdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    
    init(library: Library) {
        self.library = library
        self.tags = self.library.tags.all
    }
    
    func getZoomSize() -> CGFloat {
        var viewSizes: [LibraryZoom: CGFloat] = [:]
        switch self.viewType {
        case .Grid:
            viewSizes = GRID_VIEW_SIZES
        case .List:
            viewSizes = LIST_VIEW_SIZES
        case .Masonry:
            viewSizes = GRID_VIEW_SIZES
        }
        print(viewSizes[self.zoom] ?? 0)
        return viewSizes[self.zoom] ?? 0
    }
    
    func getViewGrid(_ geometry: GeometryProxy) -> [GridItem] {
        let entriesInRow = (geometry.size.width / getZoomSize()).rounded(.down)
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
    
    func isEntryQualifyingSearch(_ entry: Entry) -> Bool {
        if searchQuery == "" && self.tagFilters.isEmpty {
            return true
        }
        
        var qualifiesSearch = true
        if searchQuery != "" {
            qualifiesSearch = entry.path.lowercased().contains(searchQuery.lowercased())
        }
        if !entry.tags.containsAll(tagFilters)  {
            qualifiesSearch = false
        }
        
        return qualifiesSearch
    }
    
    func isEntryUntagged(_ entry: Entry) -> Bool {
        if !filterUntagged {return true}
        return filterUntagged && entry.tags.isEmpty
    }
    
    func isEntryVisable(_ entry: Entry) -> Bool {
        !isEntryHidden(entry) && isEntryQualifyingSearch(entry) && isEntryUntagged(entry)
    }
    
    var body: some View {
        @Bindable var appState = appState
        GeometryReader { geometry in
            switch self.viewType {
            case .Grid:
                ScrollView {
                    if self.library.migrationState != .MigrationNotRequired && !self.migrationClosed {
                        MigrationProgress(library: library, closed: $migrationClosed)
                    }
                    LazyVGrid(columns: getViewGrid(geometry), spacing: namesShown ? 8 : 1) {
                        ForEach(library.entries.all, id: \.path) { entry in
                            if isEntryVisable(entry) {
                                GridRow {
                                    EntryMiniView(entry: entry, namesShown: $namesShown)
                                }
                            }
                        }
                    }.padding(namesShown ? namedPadding : unnamedPadding)
                }
            case .List:
                List {
                    ForEach(library.entries.all, id: \.path) { entry in
                        if isEntryVisable(entry) {
                            NavigationLink(destination: EntryView(entry: entry).id(entry.id)){
                                HStack {
                                    EntryPreView(entry: entry, square: true)
                                        .clipShape(.rect(cornerRadius: 8))
                                        .frame(maxHeight: getZoomSize())
                                    VStack {
                                        Text(entry.path).lineLimit(2)
                                    }
                                }
                            }
                        }
                    }
                }
                .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
                    return 0
                }
            case .Masonry:
                EmptyView()
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
                        if self.zoom == .Large {
                            self.zoom = .Medium
                        } else {
                            self.zoom = .Large
                        }
                    }) {
                        Label(self.zoom == .Large ? "Zoom Out" : "Zoom In", systemImage: self.zoom == .Large ? "minus.magnifyingglass" : "plus.magnifyingglass")
                    }
                    Picker("", selection: $viewType) {
                        Label("Grid", systemImage: "square.grid.2x2").tag(LibraryViewType.Grid)
                        Label("List", systemImage: "list.bullet").tag(LibraryViewType.List)
                    }
                    if viewType == .Grid {
                        Button(action: {
                            self.namesShown.toggle()
                        }) {
                            Label(self.namesShown ? "Hide Names" : "Show Names", systemImage: "textformat")
                        }
                    }
                    Menu {
                        Toggle(isOn: $filterUntagged) {
                            Label("Untagged Entries", systemImage: "tag.slash")
                        }
                        Toggle(isOn: $hiddenShown) {
                            Label("Hidden Entries", systemImage: "eye.slash")
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease")
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
        .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always))
        .searchPresentationToolbarBehavior(.avoidHidingContent)
    }
}


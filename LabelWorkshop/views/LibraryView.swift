import SwiftUI

enum LibraryZoom: CGFloat {
    case XXLarge
    case XLarge
    case Large
    case Medium
    case Small
}

enum LibraryViewType {
    case Grid
    case List
    case Masonry
}

func openTagManager(appState: AppState, openWindow: OpenWindowAction) {
    if UIDevice.current.userInterfaceIdiom == .phone {
        appState.showTagManager = true
    } else {
        if !appState.tagManagerWindowOpen {
            openWindow(id: "tag-manager")
        }
    }
}

struct LibraryCommands: Commands {
    @Bindable var appState: AppState
    @Environment(\.openWindow) private var openWindow
    
    var body: some Commands {
        CommandMenu("Library") {
            Button("Tag Manager", systemImage: "tag") {
                openTagManager(appState: appState, openWindow: openWindow)
            }
            .keyboardShortcut(KeyboardShortcut("M", modifiers: [.command, .shift]))
        }
    }
}

struct LibraryZoomButtons: View {
    @Binding var zoom: LibraryZoom
    
    func setZoomLevel(_ zoomIndex: Int) {
        let zooms: [LibraryZoom] = [
            .Small,
            .Medium,
            .Large,
            .XLarge,
            .XXLarge
        ]
        
        let currentZoomIndex = zooms.firstIndex(of: zoom) ?? 0
        let newZoomIndex = currentZoomIndex + zoomIndex
        guard newZoomIndex >= 0 && newZoomIndex < zooms.count else {return}
        zoom = zooms[newZoomIndex]
    }
    
    var body: some View {
        Button(action: {
            setZoomLevel(+1)
        }) {
            Label("Zoom In", systemImage: "plus.magnifyingglass")
        }
        .disabled(zoom == .XXLarge)
        Button(action: {
            setZoomLevel(-1)
        }) {
            Label("Zoom Out", systemImage: "minus.magnifyingglass")
        }
        .disabled(zoom == .Small)
    }
}

struct LibraryTagManagerButton: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(AppState.self) private var appState
    
    var body: some View {
        Button(action: {
            openTagManager(appState: appState, openWindow: openWindow)
        }) {
            Label("Tag Manager", systemImage: "tag")
        }
    }
}

struct LibraryColorManagerButton: View {
    @Binding var showColorManager: Bool
    
    var body: some View {
        Button {
            showColorManager = true
        } label: {
            Label("Color Manager", systemImage: "paintpalette")
        }
    }
}

struct LibraryFilterButton: View {
    @Binding var filterUntagged: Bool
    @Binding var hiddenShown: Bool
    @Binding var tagFilters: [Tag]
    var library: Library
    @Binding var tags: [Tag]
    @Binding var showTagFilter: Bool
    
    var body: some View {
        Menu {
            Toggle(isOn: $filterUntagged) {
                Label("Untagged Entries", systemImage: "tag.slash")
            }
            Toggle(isOn: $hiddenShown) {
                Label("Hidden Entries", systemImage: "eye.slash")
            }
            LibraryTagFilterButton(showTagFilter: $showTagFilter, tagFilters: $tagFilters, library: library, tags: $tags)
        } label: {
            Label("Filter", systemImage: "line.3.horizontal.decrease")
        }
    }
}

struct LibraryViewPicker: View {
    @Binding var viewType: LibraryViewType
    
    var body: some View {
        Picker("", selection: $viewType) {
            Label("Grid", systemImage: "square.grid.2x2").tag(LibraryViewType.Grid)
            Label("List", systemImage: "list.bullet").tag(LibraryViewType.List)
        }
    }
}

struct LibraryHideNamesButton: View {
    @Binding var namesShown: Bool
    
    var body: some View {
        Button(action: {
            self.namesShown.toggle()
        }) {
            Label(self.namesShown ? "Hide Names" : "Show Names", systemImage: "textformat")
        }
    }
}

struct LibraryTagFilterButton: View {
    @Binding var showTagFilter: Bool
    @Binding var tagFilters: [Tag]
    var library: Library
    @Binding var tags: [Tag]
    private let tagFilterTip = TagFilterTip()
    
    var body: some View {
        Button(action: {
            showTagFilter = true
            tagFilterTip.invalidate(reason: .actionPerformed)
        }) {
            Label("Tags", systemImage: tagFilters.isEmpty ? "tag" : "tag.fill")
        }
        .tint(tagFilters.isEmpty ? .primary : .blue)
        .popoverTip(tagFilterTip, arrowEdge: .bottom)
    }
}

struct LibraryView: View {
    let library: Library
    @State var tags: [Tag] = []
    
    // Sheets
    @State var showTagfilter: Bool = false
    @State var migrationClosed: Bool = false
    @State var showColorManager: Bool = false
    
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
    @Environment(\.openURL) private var openURL
    @Environment(\.openWindow) private var openWindow
    
    let LIST_VIEW_SIZES: [LibraryZoom: CGFloat] = [
        .XXLarge: 120,
        .XLarge: 100,
        .Large: 50,
        .Medium: 30,
        .Small: 20
    ]
    let GRID_VIEW_SIZES: [LibraryZoom: CGFloat] = [
        .XXLarge: 1000,
        .XLarge: 200,
        .Large: 120,
        .Medium: 70,
        .Small: 55
    ]
    
    private let namedPadding: EdgeInsets = EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
    private let unnamedPadding: EdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    
    init(library: Library) {
        self.library = library
        self.tags = self.library.tags.tags
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
        return viewSizes[self.zoom] ?? 0
    }
    
    func getViewGrid(_ geometry: GeometryProxy) -> [GridItem] {
        var entriesInRow = (geometry.size.width / getZoomSize()).rounded(.down)
        if entriesInRow < 1 { entriesInRow = 1 }
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
                    if self.library.migrator.state != .MigrationNotRequired && !self.migrationClosed {
                        MigrationProgress(library: library, closed: $migrationClosed)
                    }
                    LazyVGrid(columns: getViewGrid(geometry), spacing: namesShown ? 8 : 1) {
                        ForEach(library.entries.all, id: \.path) { entry in
                            if isEntryVisable(entry) {
                                GridRow {
                                    EntryMiniView(entry: .constant(entry), namesShown: $namesShown)
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
            ToolbarItemGroup(placement: .topBarTrailing){
                ControlGroup {
                    LibraryZoomButtons(zoom: $zoom)
                    if viewType == .Grid {
                        LibraryHideNamesButton(namesShown: $namesShown)
                    }
                    LibraryViewPicker(viewType: $viewType)
                        .fixedSize()
                } label: {
                    Label("View Options", systemImage: viewType == .Grid ? "square.grid.2x2" : "list.bullet" )
                }
                LibraryFilterButton(filterUntagged: $filterUntagged, hiddenShown: $hiddenShown, tagFilters: $tagFilters, library: library, tags: $tags, showTagFilter: $showTagfilter)
            }
            
            ToolbarItemGroup(placement: .secondaryAction) {
                LibraryTagManagerButton()
                LibraryColorManagerButton(showColorManager: $showColorManager)
            }
        }
        .sheet(isPresented: $appState.showTagManager) {
            TagManagerView(appState)
        }
        .sheet(isPresented: $showColorManager) {
            ColorManager(tagColors: self.library.tagColors)
        }
        .sheet(isPresented: $showTagfilter) {
            TagSearch(library: self.library, tags: $tags, selectAction: addTagToFilter, multiSelect: true, selected: self.tagFilters, closeButton: true)
                .onAppear {
                    self.library.tags.refresh()
                    self.tags = self.library.tags.tags
                }
        }
        .navigationTitle(library.getName())
        .searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always))
        .searchPresentationToolbarBehavior(.avoidHidingContent)
    }
}


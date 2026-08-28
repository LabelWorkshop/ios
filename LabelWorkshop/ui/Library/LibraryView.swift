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

func openSheetWindow(_ windowName: String, sheetBinding: Binding<Bool>, openWindow: OpenWindowAction) {
    if UIDevice.current.userInterfaceIdiom == .phone {
        sheetBinding.wrappedValue = true
    } else {
        openWindow(id: windowName)
    }
}

struct LibraryCommands: Commands {
    @Bindable var appState: AppState
    @Environment(\.openWindow) private var openWindow
    
    var body: some Commands {
        CommandMenu("Library") {
            Button("Tag Manager", systemImage: "tag") {
                openSheetWindow("tag-manager", sheetBinding: $appState.showTagManager, openWindow: openWindow)
            }
            .keyboardShortcut(KeyboardShortcut("M", modifiers: [.command, .shift]))
        }
    }
}

struct LibraryZoomButtons: View {
    @Binding var zoom: LibraryZoom
    var setZoomLevel: (Int) -> Void
    
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
        @Bindable var appState = appState
        Button(action: {
            openSheetWindow("tag-manager", sheetBinding: $appState.showTagManager, openWindow: openWindow)
        }) {
            Label("Tag Manager", systemImage: "tag")
        }
    }
}

struct LibraryColorManagerButton: View {
    @Environment(\.openWindow) private var openWindow
    @Binding var showColorManager: Bool
    
    var body: some View {
        Button {
            openSheetWindow("color-manager", sheetBinding: $showColorManager, openWindow: openWindow)
        } label: {
            Label("Color Manager", systemImage: "paintpalette")
        }
    }
}

struct LibraryInfoButton: View {
    @Environment(\.openWindow) private var openWindow
    @Binding var showLibraryInfo: Bool
    
    var body: some View {
        Button {
            openSheetWindow("color-manager", sheetBinding: $showLibraryInfo, openWindow: openWindow)
        } label: {
            Label("Library Info", systemImage: "info")
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

struct LibraryImportButton: View {
    @Binding var showFilePicker: Bool
    
    var body: some View {
        Button(action: {
            showFilePicker = true
        }) {
            Label("Import File", systemImage: "square.and.arrow.down")
        }
    }
}

struct LibrarySortButton: View {
    @Binding var sort: SortType
    @Binding var ascending: Bool
    
    var body: some View {
        Menu {
            Picker("Sort By", selection: $sort) {
                Text("Date Added").tag(SortType.id)
                Text("Path").tag(SortType.path)
                Text("Filename").tag(SortType.filename)
            }
            Picker("Sort Order", selection: $ascending) {
                Text("Ascending").tag(true)
                Text("Descending").tag(false)
            }
        
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }
}

struct LibraryViewOptionsButton: View {
    @Binding var zoom: LibraryZoom
    @Binding var viewType: LibraryViewType
    @Binding var namesShown: Bool
    var setZoomLevel: (Int) -> Void
    
    var body: some View {
        Menu {
            LibraryZoomButtons(zoom: $zoom, setZoomLevel: setZoomLevel)
            if viewType == .Grid {
                LibraryHideNamesButton(namesShown: $namesShown)
            }
            LibraryViewPicker(viewType: $viewType)
                .fixedSize()
        } label: {
            Label("View Options", systemImage: viewType == .Grid ? "square.grid.2x2" : "list.bullet" )
        }
    }
}

struct LibraryView: View {
    let library: Library
    @State var tags: [Tag] = []
    
    // Sheets
    @State var showTagfilter: Bool = false
    @State var migrationClosed: Bool = false
    @State var showColorManager: Bool = false
    @State var deletionError: Bool = false
    @State var showLibraryInfo: Bool = false
    @State var showFilePicker = false
    @State var importError = false
    
    // Filtering
    @State var searchQuery: String = ""
    @State var tagFilters: [Tag] = []
    
    // View Options
    @State var zoom: LibraryZoom = .Large
    @State var namesShown: Bool = true
    @State var hiddenShown: Bool = false
    @State var filterUntagged: Bool = false
    @State var viewType: LibraryViewType = .Grid
    @State private var magnificationValue: CGFloat = 1.0
    @State private var isPinching = false
    @State var sort: SortType = .id
    @State var ascending: Bool = true
    
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL
    @Environment(\.openWindow) private var openWindow
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
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
        withAnimation(.spring()) {
            zoom = zooms[newZoomIndex]
        }
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
        guard let tags = entry.tags else {return false}
        if hiddenShown {return false}
        else if !tags.isHidden {return false}
        return true
    }
    
    func isEntryQualifyingSearch(_ entry: Entry) -> Bool {
        if searchQuery == "" {
            return true
        }
        return entry.path.localizedCaseInsensitiveContains(searchQuery)
    }
    
    func isEntryUntagged(_ entry: Entry) -> Bool {
        if !filterUntagged {return true}
        return filterUntagged && entry.tags?.isEmpty ?? true
    }
    
    func isEntryHaveTags(_ entry: Entry) -> Bool {
        guard let tags = entry.tags else {return true}
        if tagFilters.isEmpty {
            return true
        }
        
        return tags.containsAll(tagFilters)
    }
    
    func isEntryVisable(_ entry: Entry) -> Bool {
        !isEntryHidden(entry) &&
        isEntryQualifyingSearch(entry) &&
        isEntryUntagged(entry) &&
        isEntryHaveTags(entry)
    }
    
    func lookaheadRender(for entry: Entry) {
        guard let idx = library.entries.getIndex(of: entry) else {return}
        let lookahead = 20
        for i in idx..<min(idx + lookahead, library.entries.all.count) {
            Task(priority: .utility) {
                await ThumbnailLoader.shared.thumbnail(
                    for: library.entries.all[i],
                    square: true
                )
            }
        }
    }
    
    var body: some View {
        @Bindable var appState = appState
        GeometryReader { geometry in
            let sortedEntries = library.entries.getSorted(sort, ascending: ascending)
            switch self.viewType {
            case .Grid:
                let columns = getViewGrid(geometry)
                let itemSpacing: CGFloat = namesShown ? 8 : 1
                ScrollView {
                    if let migrator = library.migrator, !self.migrationClosed {
                        MigrationProgress(migrator: migrator, closed: $migrationClosed)
                    }
                    LazyVGrid(columns: columns, spacing: itemSpacing) {
                        ForEach(sortedEntries.filter { isEntryVisable($0) }, id: \.path) { entry in
                            GridRow {
                                EntryMiniView(entry: .constant(entry), namesShown: $namesShown, disabled: $isPinching)
                                    .onAppear { lookaheadRender(for: entry) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }.padding(namesShown ? namedPadding : unnamedPadding)
                    .if(appState.pinchZoom) { view in
                        view.scaleEffect(magnificationValue, anchor: .top)
                    }
                    .animation(.interactiveSpring(), value: magnificationValue)
                    .animation(.smooth, value: namesShown)
                }
                .simultaneousGesture(
                    MagnifyGesture()
                        .onChanged { value in
                            isPinching = true
                            magnificationValue = max(0.7, min(value.magnification, 1.3))
                        }
                        .onEnded { value in
                            isPinching = false
                            guard appState.pinchZoom else {return}
                            
                            if value.magnification > 1.3 {
                                setZoomLevel(+1)
                            }
                            if value.magnification < 0.7 {
                                setZoomLevel(-1)
                            }
                            
                            withAnimation(.spring()) {
                                magnificationValue = 1.0
                            }
                        }
                )
            case .List:
                List {
                    ForEach(sortedEntries.filter { isEntryVisable($0) }, id: \.path) { entry in
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
                        .contextMenu {
                            EntryContextMenu(entry: .constant(entry), deletionError: $deletionError)
                        }
                        .onAppear { lookaheadRender(for: entry) }
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
            ToolbarItem(placement: .bottomBar){
                LibraryImportButton(showFilePicker: $showFilePicker)
            }

            if #available(iOS 26.0, *) {
                ToolbarSpacer(.flexible, placement: .bottomBar)
            }

            ToolbarItem(placement: .bottomBar){
                LibraryViewOptionsButton(zoom: $zoom, viewType: $viewType, namesShown: $namesShown, setZoomLevel: setZoomLevel)
            }

            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .bottomBar)
            }

            ToolbarItemGroup(placement: .bottomBar){
                LibraryFilterButton(filterUntagged: $filterUntagged, hiddenShown: $hiddenShown, tagFilters: $tagFilters, library: library, tags: $tags, showTagFilter: $showTagfilter)

                LibrarySortButton(sort: $sort, ascending: $ascending)
            }

            ToolbarItemGroup(placement: .secondaryAction) {
                LibraryTagManagerButton()
                LibraryColorManagerButton(showColorManager: $showColorManager)
                LibraryInfoButton(showLibraryInfo: $showLibraryInfo)
            }
        }
        .sheet(isPresented: $appState.showTagManager) {
            TagManagerView(appState)
        }
        .sheet(isPresented: $showColorManager) {
            ColorManager(library: self.library)
        }
        .sheet(isPresented: $showLibraryInfo) {
            LibraryInfoPanel(library: library)
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
        .alert("Delete Failed", isPresented: $deletionError) {
        } message: {
            Text("An error occured while trying to delete this entry.")
        }
        .alert("Import Failed", isPresented: $importError) {
        } message: {
            Text("An error occured while trying to import an item.")
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.item]
        ) { result in
            switch result {
            case .success(let file):
                guard file.startAccessingSecurityScopedResource() else { return }
                defer { file.stopAccessingSecurityScopedResource() }
                
                do {
                    let filename = file.lastPathComponent
                    let fileData = try Data(contentsOf: file)
                    let targetURL = library.bookmark.appendingPathComponent(filename)
                    try fileData.write(to: targetURL)
                } catch {
                    print(error)
                }
                
                Task(priority: .background) {
                    do {
                        try library.addNewEntries()
                    } catch {
                        print(error)
                        importError = true
                    }
                }
            case .failure(let error):
                print(error)
                importError = true
            }
        }
    }
}


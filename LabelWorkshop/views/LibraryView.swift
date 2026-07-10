import SwiftUI

struct LibraryView: View {
    let library: Library
    @State var entries: [Entry]
    @State var tags: [Tag] = []
    
    @State private var showTagManager: Bool = false
    @State var showTagfilter: Bool = false
    @State var searchQuery: String = ""
    @State var tagFilters: [Tag] = []
    @State var shownEntries: [Entry]
    
    private let tagFilterTip = TagFilterTip()
    
    private static let columnsPhone: [GridItem] = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    private static let columnsPad: [GridItem] = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    init(library: Library) {
        self.library = library
        self.entries = library.safeGetEntries(limit: 30)
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
            if qualifiesSearch && entry.containsAllTags(tagFilters)  {
                updatedEntriesList.append(entry)
            }
        }
        self.shownEntries = updatedEntriesList
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVGrid(columns: geometry.size.width < 600 ? LibraryView.columnsPhone : LibraryView.columnsPad) {
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
                } label: {
                    Image(systemName: "ellipsis.circle")
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
                    NavigationView {
                        ScrollView {
                            VStack {
                                ForEach(tags, id: \.id) { tag in
                                    HStack {
                                        Image(systemName: tagFilters.contains(where: { filterTag in return filterTag.id == tag.id}) ? "checkmark.circle" : "circle")
                                        Button(action: {
                                            if tagFilters.contains(where: { filterTag in
                                                return filterTag.id == tag.id
                                            }) {
                                                tagFilters.removeAll(where: { filterTag in
                                                    return filterTag.id == tag.id
                                                })
                                            } else {
                                                tagFilters.append(tag)
                                            }
                                        }) {
                                            TagPreView(name: .constant(tag.name), colors: .constant(tag.colors), fullWidth: true)
                                        }
                                    }
                                }
                            }
                            .padding(16)
                        }
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading){
                                Button(action: {
                                    showTagfilter = false
                                }) {
                                    Image(systemName: "chevron.backward")
                                }
                            }
                            ToolbarItem(placement: .bottomBar){
                                Button(action: {
                                    tagFilters = []
                                }) {
                                    Text("Deselect All")
                                }
                            }
                        }
                    }
                    .task {
                        self.tags = Tag.fetchAll(library: self.library)
                    }
                }
            }
        }
        .sheet(isPresented: $showTagManager) {
            TagManagerView(library: library)
        }
        .navigationTitle(library.getName())
        .onAppear {
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


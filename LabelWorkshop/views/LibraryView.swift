import SwiftUI

struct LibraryView: View {
    let library: Library
    @State var entries: [Entry]
    
    @State private var showTagManager: Bool = false
    @State var showTagfilter: Bool = false
    @State var searchQuery: String = ""
    @State var tagFilters: [Tag] = []
    @State var shownEntries: [Entry]
    
    @Environment(\.openURL) private var openURL
    
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
            if qualifiesSearch && entry.tags.containsAll(tagFilters)  {
                updatedEntriesList.append(entry)
            }
        }
        self.shownEntries = updatedEntriesList
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
                    TagSearch(library: self.library, tags: self.library.tags.all, selectAction: addTagToFilter, multiSelect: true, selected: self.tagFilters, closeButton: true)
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


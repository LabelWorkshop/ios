import SwiftUI

func loadImage(for entry: Entry) -> UIImage? {
    guard let path = entry.fullPath else { return nil }
    guard let bookmark = entry.library.bookmark else { return nil }
    guard bookmark.startAccessingSecurityScopedResource() else { return nil }
    defer { bookmark.stopAccessingSecurityScopedResource() }
    if let data = try? Data(contentsOf: path) {
        let uiImage = UIImage(data: data)
        return uiImage
    }
    return nil
}

struct LibraryView: View {
    let library: Library
    
    @State private var showTagManager: Bool = false
    
    private static let columnsPhone: [GridItem] = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    private static let columnsPad: [GridItem] = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    init(library: Library) {
        self.library = library
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVGrid(columns: geometry.size.width < 600 ? LibraryView.columnsPhone : LibraryView.columnsPad) {
                    ForEach (library.safeGetEntries(), id: \.path) { entry in
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
                        Label("tag.manager", systemImage: "tag")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showTagManager) {
            TagManagerView(library: library)
        }
        .navigationTitle(library.getName())
    }
}

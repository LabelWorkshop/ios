import SwiftUI

func loadImage(for entry: Entry) -> UIImage? {
    guard let path = entry.fullPath else { return nil }
    guard path.startAccessingSecurityScopedResource() else { return nil }
    defer { path.stopAccessingSecurityScopedResource() }
    if let data = try? Data(contentsOf: path) {
        let uiImage = UIImage(data: data)
        return uiImage
    }
    return nil
}

struct LibraryView: View {
    let library: Library
    let columns: [GridItem]
    
    private static let columnsPhone: [GridItem] = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    private static let columnsPad: [GridItem] = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    init(library: Library) {
        self.library = library
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.columns = LibraryView.columnsPhone
        } else {
            self.columns = LibraryView.columnsPad
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach (library.safeGetEntries(), id: \.path) { entry in
                    GridRow {
                        EntryMiniView(entry: entry)
                    }
                }
            }.padding(16)
        }
        .navigationTitle(library.getName())
    }
}

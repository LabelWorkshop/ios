import SwiftUI
import SwiftData
import Foundation

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query var libraries: [Library]
    
    @State private var selectedLibrary: Library?
    @State private var visibility: NavigationSplitViewVisibility = .all
    @State private var showFileImporter = false
    
    var body: some View {
        NavigationSplitView(columnVisibility: $visibility) {
            List(selection: $selectedLibrary) {
                ForEach(libraries){ library in
                    NavigationLink(value: library){
                        Text(library.getName())
                    }
                }
            }
            .toolbar {
                ToolbarItem( placement: .navigationBarTrailing){
                    Button(action: {
                        showFileImporter = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem( placement: .topBarLeading){
                    let btn = Button(action: {
                        visibility = .doubleColumn
                    }) {
                        Image(systemName: "sidebar.leading")
                    }
                    if UIDevice.current.userInterfaceIdiom == .phone {btn.hidden()}
                    btn
                }
            }
            .navigationTitle("LabelWorkshop")
        } content: {
            if let selectedLibrary {
                LibraryView(library: selectedLibrary).navigationSplitViewColumnWidth(700)
            }
        } detail: {}
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.folder]
        ) { result in
            switch result {
            case .success(let folder):
                let gotAccess = folder.startAccessingSecurityScopedResource()
                if !gotAccess { return }
                let id = UUID().uuidString
                do {
                    let bookmark = try folder.bookmarkData(
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                    UserDefaults.standard.set(bookmark, forKey: id)
                } catch {
                    print(error)
                }
                let newLibrary: Library = Library(bookmarkKey: id)
                context.insert(newLibrary)
                folder.stopAccessingSecurityScopedResource()
            case .failure(let error):
                print(error)
            }
        }
    }
}

#Preview {
    ContentView()
}

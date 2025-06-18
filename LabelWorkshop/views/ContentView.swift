import SwiftUI
import SwiftData
import Foundation

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query var libraries: [Library]
    
    @State private var showFileImporter = false
    var body: some View {
        NavigationView {
            List {
                ForEach(libraries){ library in
                    NavigationLink(destination: LibraryView(library: library)){
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
            }
            .navigationTitle("LabelWorkshop")
            .listStyle(SidebarListStyle())
        }
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

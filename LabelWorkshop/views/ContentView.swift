import SwiftUI
import Foundation

struct ContentView: View {
    @State private var libraries: [Library]
    
    @State private var selectedLibrary: Library?
    @State private var visibility: NavigationSplitViewVisibility = .all
    @State private var showFileImporter = false
    @State private var showAbout = false
    
    init() {
        if UserDefaults.standard.bool(forKey: "reset_on_launch") {
            UserDefaults.standard.set(false, forKey: "reset_on_launch")
            ContentView.setRawLibraries([])
        }
        
        let rawLibraries: [String] = ContentView.getRawLibraries()
        var newLibraries: [Library] = []
        for rawLibrary in rawLibraries {
            newLibraries.append(
                Library(bookmarkKey: rawLibrary)
            )
        }
        self.libraries = newLibraries
    }
    
    static func getRawLibraries() -> [String] {
        return UserDefaults.standard.object(forKey: "libraries") as? [String] ?? [String]()
    }
    
    static func setRawLibraries(_ rawLibraries: [String]) {
        UserDefaults.standard.set(rawLibraries, forKey: "libraries")
    }
    
    func addLibrary(_ bookmarkKey: String) {
        var rawLibraries = ContentView.getRawLibraries()
        rawLibraries.append(bookmarkKey)
        ContentView.setRawLibraries(rawLibraries)
        libraries.append(Library(bookmarkKey: bookmarkKey))
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $visibility) {
            List(selection: $selectedLibrary) {
                ForEach(libraries){ library in
                    NavigationLink(value: library){
                        Text(library.getName())
                    }
                }.onDelete(perform: removeLibrary)
            }
            .toolbar {
                ToolbarItem( placement: .navigationBarTrailing){
                    Button(action: {
                        showFileImporter = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading){
                    Button(action: {
                        showAbout = true
                    }) {
                        Image(systemName: "info.circle")
                    }
                    .sheet(isPresented: $showAbout, content: { AboutView() })
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
                addLibrary(id)
                folder.stopAccessingSecurityScopedResource()
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func removeLibrary(at indexSet: IndexSet){
        var rawLibraries = ContentView.getRawLibraries()
        for index in indexSet {
            rawLibraries.remove(at: index)
        }
        ContentView.setRawLibraries(rawLibraries)
    }
}

#Preview {
    ContentView()
}

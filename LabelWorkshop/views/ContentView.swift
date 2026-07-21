import SwiftUI
import Foundation
import TipKit

struct ContentView: View {
    @State private var libraries: [Library]
    
    @State private var visibility: NavigationSplitViewVisibility = .all
    @State private var showFileImporter = false
    @State private var showAbout = false
    
    @Environment(AppState.self) private var appState
    
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
        // try? Tips.resetDatastore()
        try? Tips.configure()
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
        @Bindable var appState = appState
        NavigationSplitView(columnVisibility: $visibility) {
            List(selection: $appState.selectedLibrary) {
                ForEach(libraries){ library in
                    NavigationLink(value: library){
                        Text(library.getName())
                    }
                }.onDelete(perform: removeLibrary)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading){
                    Button(action: {
                        showAbout = true
                    }) {
                        Image(systemName: "info")
                    }
                    .sheet(isPresented: $showAbout, content: { AboutView() })
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    showFileImporter = true
                }) {
                    Label("Add Library", systemImage: "plus")
                        .padding(16)
                }
                .buttonStyle(ProminentButtonStyle())
            }
            .navigationTitle("LabelWorkshop")
            .toolbarTitleDisplayMode(.large)
        } content: {
            if let library = appState.selectedLibrary {
                LibraryView(library: library)
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

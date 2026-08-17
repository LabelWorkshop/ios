import SwiftUI

@Observable
final class AppState {
    var showTagManager = false
    var tagManagerWindowOpen = false
    var selectedLibrary: Library?
    var pinchZoom: Bool = false
    var showWhatsNew: Bool = false
}

@main
struct LabelWorkshopApp: App {
    @State private var appState = AppState()
    
    static var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .commands {
            LibraryCommands(appState: appState)
        }
        
        WindowGroup(id:"tag-manager") {
            TagManagerView(appState)
                .onAppear {appState.tagManagerWindowOpen = true}
                .onDisappear {appState.tagManagerWindowOpen = false}
        }
        .defaultSize(width: 300, height: 600)
        
        WindowGroup(id:"tag-editor", for: Int.self) { $tagId in
            if let library = appState.selectedLibrary, let tag = library.tags.getById(id: tagId ?? -1) {
                TagDetailsView(library: library, tag: tag)
            }
        }
        .defaultSize(width: 300, height: 600)
        
        WindowGroup("Color Manager", id:"color-manager") {
            ColorManager(library: appState.selectedLibrary)
        }
        
        WindowGroup("Library Info", id: "library-info") {
            LibraryInfoPanel(library: appState.selectedLibrary)
        }
    }
}

import SwiftUI

@Observable
final class AppState {
    var showTagManager = false
    var tagManagerWindowOpen = false
    var selectedLibrary: Library?
}

@main
struct LabelWorkshopApp: App {
    @State private var appState = AppState() 
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .commands {
            LibraryCommands(appState: appState)
        }
        
        WindowGroup(id:"tag-manager") {
            if appState.selectedLibrary != nil {
                TagManagerView(library: appState.selectedLibrary!)
                    .onAppear {appState.tagManagerWindowOpen = true}
                    .onDisappear {appState.tagManagerWindowOpen = false}
            }
        }
        .defaultSize(width: 300, height: 600)
    }
}

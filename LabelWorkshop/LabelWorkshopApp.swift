import SwiftUI

@Observable
final class AppState {
    var showTagManager = false
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
    }
}

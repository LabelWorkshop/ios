import SwiftUI
import SwiftData

@main
struct LabelWorkshopApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [
                    Library.self
                ])
        }
    }
}

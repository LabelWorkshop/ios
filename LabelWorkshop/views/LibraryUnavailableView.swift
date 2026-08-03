import SwiftUI

struct LibraryUnavailableView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Library Selected", systemImage: "square.stack")
        }
    }
}

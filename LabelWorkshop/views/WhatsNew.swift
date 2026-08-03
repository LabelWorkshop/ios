import SwiftUI

struct WhatsNew<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @Environment(AppState.self) private var appState
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text("What's New in LabelWorkshop").font(.largeTitle).bold()
                    .padding(EdgeInsets(top: 40, leading: 16, bottom: 0, trailing: 16))
                VStack(spacing: 8) {
                    content()
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        appState.showWhatsNew = false
                    } label: {
                        Text("Continue")
                    }
                    .buttonStyle(ProminentButtonStyle())
                }
            }
        }
    }
}

struct Version030WhatsNew: View {
    var body: some View {
        WhatsNew {
            NewVersionTip(
                icon: Image(systemName: "interface.window.stack").symbolRenderingMode(.multicolor),
                title: "Windows",
                description: "On iPadOS, some dialogs now open in their own window instead of as a sheet."
            )
            NewVersionTip(
                icon: Image(systemName: "paintpalette.fill").symbolRenderingMode(.multicolor),
                title: "Color Manager",
                description: "Create and edit colors directly in the app, then assign them to tags using the redesigned color picker."
            )
            NewVersionTip(
                icon: Image(systemName: "list.bullet"),
                title: "List View",
                description: "Choose from additional zoom levels or switch to the new list view.",
                iconTint: .purple
            )
            NewVersionTip(
                icon: Image(systemName: "square.stack.3d.forward.dottedline"),
                title: "GIF Preview",
                description: "GIFs now animate while you view them.",
                iconTint: .blue
            )
            NewVersionTip(
                icon: Image(systemName: "arrow.up.left.and.arrow.down.right"),
                title: "Full Screen",
                description: "Open an entry in full screen by tapping its preview.",
                iconTint: .gray
            )
            NewVersionTip(
                icon: Image(systemName: "line.3.horizontal.decrease"),
                title: "More Filters",
                description: "Find entries more easily with new filters for untagged and hidden items."
            )
            NewVersionTip(
                icon: Image(systemName: "text.menu"),
                title: "Text Preview",
                description: "Preview text files directly in the app.",
                iconTint: .green
            )
            NewVersionTip(
                icon: Image("textformat.slash"),
                title: "Hide Names",
                description: "Hide entry names for a cleaner, preview-focused grid.",
                iconTint: .pink
            )
            NewVersionTip(
                icon: Image(systemName: "ant.fill"),
                title: "Bug Fixes & Performance Improvements",
                description: "This release includes stability fixes, performance improvements, and code cleanup to make the app more reliable now and easier to improve in future updates.",
                iconTint: .red
            )
        }
    }
}

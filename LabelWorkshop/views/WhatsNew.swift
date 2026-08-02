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
                icon: Image(systemName:"interface.window.stack").symbolRenderingMode(.multicolor),
                title: "Windows",
                description: "Sheets have been replaced with windows on iPadOS."
            )
            NewVersionTip(
                icon: Image(systemName:"paintpalette.fill").symbolRenderingMode(.multicolor),
                title: "Color Manager",
                description: "Create & edit colors right in the app. Assign colors to tags with the updated color picker."
            )
            NewVersionTip(
                icon: Image(systemName:"list.bullet"),
                title: "List View",
                description: "As well as more zoom sizes there is now a list view.",
                iconTint: .purple
            )
            NewVersionTip(
                icon: Image(systemName:"square.stack.3d.forward.dottedline"),
                title: "GIF Preview",
                description: "GIFs will now animate when viewing.",
                iconTint: .blue
            )
            NewVersionTip(
                icon: Image(systemName:"arrow.up.left.and.arrow.down.right"),
                title: "Full Screen",
                description: "Entries now have full screen capabilities. Tap on the preview to expand into full screen.",
                iconTint: .gray
            )
            NewVersionTip(
                icon: Image(systemName:"line.3.horizontal.decrease"),
                title: "More Filters",
                description: "Finding your entry is easier then ever with the untagged and hidden entries filter."
            )
            NewVersionTip(
                icon: Image(systemName:"text.menu"),
                title: "Text Preview",
                description: "Support for preview text files is here.",
                iconTint: .green
            )
            NewVersionTip(
                icon: Image("textformat.slash"),
                title: "Hide Names",
                description: "Get a preview focused grid by hiding the names.",
                iconTint: .pink
            )
            NewVersionTip(
                icon: Image(systemName: "ant.fill"),
                title: "Bug Squashing, Preformence Improvements, and Code Cleanup",
                description: "In 0.3.0 crashes will occur less often, and some bugs have been fixed. Some of the code has been changed to be more efficent and future proof. Future updates will expand on this by removing crashes all together.",
                iconTint: .red
            )
        }
    }
}

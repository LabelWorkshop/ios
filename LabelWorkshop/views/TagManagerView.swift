import SwiftUI

struct TagManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    private var appState: AppState
    @State var tags: [Tag]
    @State var editTag: Tag?
    
    init(_ appState: AppState) {
        self.appState = appState
        _tags = State(initialValue: [])
    }
    
    func openEditor(_ tag: Tag) {
        if UIDevice.current.userInterfaceIdiom == .phone {
            editTag = tag
        } else {
            openWindow(id: "tag-editor", value: tag.id)
        }
    }
    
    func refreshTags() {
        appState.selectedLibrary?.tags.refresh()
        self.tags = appState.selectedLibrary?.tags.all ?? []
    }
    
    var body: some View {
        NavigationStack {
            if let library = appState.selectedLibrary {
                TagSearch(library: library, tags: $tags, selectAction: openEditor, multiSelect: false, selected: [], closeButton: false)
                .navigationTitle("Tag Manager")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing){
                        Button(action: {
                            if let newTag = library.tags.new("New Tag") {
                                openEditor(newTag)
                            }
                        }) {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(ProminentButtonStyle())
                    }
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        ToolbarItem(placement: .navigationBarLeading){
                            CloseButton(dismiss: dismiss)
                        }
                    }
                }
            } else {
                Text("No Library Selected")
                    .foregroundStyle(.secondary)
                    .navigationTitle("Tag Manager")
            }
        }
        .if(UIDevice.current.userInterfaceIdiom == .phone) { view in
            view.sheet(item: $editTag) { editTag in
                if let library = appState.selectedLibrary {
                    TagDetailsView(library: library, tag: editTag)
                        .onDisappear {
                            self.refreshTags()
                        }
                }
            }
        }
        .onAppear() {
            refreshTags()
        }
        .onChange(of: appState.selectedLibrary) {
            refreshTags()
        }
    }
}

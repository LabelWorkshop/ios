import SwiftUI

struct TagManagerView: View {
    @Environment(\.dismiss) private var dismiss
    let library: Library?
    @State var tags: [Tag]
    @State var editTag: Tag?
    
    init(library: Library?) {
        self.library = library
        self.tags = self.library?.tags.all ?? []
    }
    
    func openEditor(_ tag: Tag) {
        editTag = tag
    }
    
    func refreshTags() {
        self.library?.tags.refresh()
        self.tags = self.library?.tags.all ?? []
    }
    
    var body: some View {
        NavigationStack {
            if let library = library {
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
        .sheet(item: $editTag) { editTag in
            if let library = library {
                TagDetailsView(library: library, tag: editTag)
                    .onDisappear {
                        self.refreshTags()
                    }
            }
        }
        .onAppear() {
            refreshTags()
        }
    }
}

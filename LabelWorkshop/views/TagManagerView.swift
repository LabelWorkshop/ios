import SwiftUI

struct TagManagerView: View {
    @Environment(\.dismiss) private var dismiss
    let library: Library
    @State var tags: [Tag] = []
    @State var showNewTag: Bool = false
    @State var showTagEditor: Bool = false
    @State var editTag: Tag?
    
    init(library: Library) {
        self.library = library
    }
    
    func openEditor(_ tag: Tag) {
        editTag = tag
        showTagEditor = true
    }
    
    var body: some View {
        NavigationView {
            TagSearch(library: self.library, tags: self.library.tags.all, selectAction: openEditor, multiSelect: false, selected: [], closeButton: false)
            .navigationTitle("Tag Manager")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing){
                    Button(action: {
                        showNewTag = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .sheet(isPresented: $showNewTag) {
                        let newTag = library.tags.new("New Tag")
                        if let newTag = newTag {
                            NavigationView {
                                TagDetailsView(library: library, tag: newTag)
                            }
                        }
                    }
                    .buttonStyle(ProminentButtonStyle())
                }
                
                ToolbarItem(placement: .navigationBarLeading){
                    CloseButton(dismiss: dismiss)
                }
            }.onAppear {
                self.tags = library.tags.all
            }
        }
        .sheet(item: $editTag) { editTag in
            TagDetailsView(library: library, tag: editTag)
        }
    }
}

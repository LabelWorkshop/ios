import SwiftUI

struct TagManagerView: View {
    @Environment(\.dismiss) private var dismiss
    let library: Library
    @State var tags: [Tag] = []
    @State var showNewTag: Bool = false
    
    init(library: Library) {
        self.library = library
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    ForEach($tags, id: \.id){ $tag in
                        NavigationLink(destination: TagDetailsView(library: library, tag: tag)){
                            TagView(tag: tag, fullWidth: true)
                        }
                    }
                }.padding(16)
            }
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
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarTrailing){
                                        CloseButton(dismiss: dismiss)
                                    }
                                }
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
    }
}

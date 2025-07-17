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
                        NavigationLink(destination: TagDetailsView(tag: tag)){
                            TagView(tag: tag, fullWidth: true)
                        }
                    }
                }.padding(16)
            }
            .navigationTitle("tag.manager")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading){
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                        Text("back")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing){
                    Button(action: {
                        showNewTag = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .sheet(isPresented: $showNewTag) {
                        let newTag = library.newTag("New Tag")
                        if let newTag = newTag {
                            NavigationView {
                                TagDetailsView(tag: newTag)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarLeading){
                                        Button(action: {
                                            dismiss()
                                        }) {
                                            Image(systemName: "chevron.backward")
                                            Text("back")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }.onAppear {
                self.tags = Tag.fetchAll(library: library)
            }
        }
    }
}

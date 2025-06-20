import SwiftUI

struct TagManagerView: View {
    @Environment(\.dismiss) private var dismiss
    let library: Library
    
    init(library: Library) {
        self.library = library
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    ForEach(Tag.fetchAll(library: library), id: \.id){ tag in
                        NavigationLink(destination: TagDetailsView(tag: tag)){
                            TagView(tag: tag, fullWidth: true)
                        }
                    }
                }.padding(16)
            }
            .navigationTitle("Tag Manager")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading){
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                        Text("Back")
                    }
                }
            }
        }
    }
}

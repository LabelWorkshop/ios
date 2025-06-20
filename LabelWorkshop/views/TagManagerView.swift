import SwiftUI

struct TagManagerView: View {
    let library: Library
    
    init(library: Library) {
        self.library = library
    }
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(Tag.fetchAll(library: library), id: \.id){ tag in
                    TagView(tag: tag, fullWidth: true)
                }
            }.padding(16)
        }
        .navigationTitle("Tag Manager")
    }
}

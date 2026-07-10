import SwiftUI

struct TagFilterView: View {
    @Binding var tags: [Tag]
    @Binding var tagFilters: [Tag]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    ForEach(tags, id: \.id) { tag in
                        HStack {
                            Image(systemName: tagFilters.contains(where: { filterTag in return filterTag.id == tag.id}) ? "checkmark.circle" : "circle")
                            Button(action: {
                                if tagFilters.contains(where: { filterTag in
                                    return filterTag.id == tag.id
                                }) {
                                    tagFilters.removeAll(where: { filterTag in
                                        return filterTag.id == tag.id
                                    })
                                } else {
                                    tagFilters.append(tag)
                                }
                            }) {
                                TagPreView(name: .constant(tag.name), colors: .constant(tag.colors), fullWidth: true)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading){
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                    }
                }
                ToolbarItem(placement: .bottomBar){
                    Button(action: {
                        tagFilters = []
                    }) {
                        Text("Deselect All")
                    }
                }
            }
        }
    }
}

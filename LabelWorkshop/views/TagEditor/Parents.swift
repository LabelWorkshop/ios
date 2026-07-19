import SwiftUI

struct TagEditorParents: View {
    @Binding var parentTags: [Tag]
    @Binding var disambiguationId: Int?
    @State var showTagParentSelector: Bool = false
    var tagId: Int
    var tags: [Tag]
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach($parentTags){ $tag in
                    HStack {
                        Button(action: {
                            if disambiguationId != tag.id {
                                disambiguationId = tag.id
                            } else {
                                disambiguationId = nil
                            }
                        }, label: {
                            HStack {
                                Image(systemName: disambiguationId == tag.id ? "checkmark.circle" : "circle").font(.title)
                            }
                        })
                        TagView(tag: tag, fullWidth: true)
                        Button(role: .destructive, action: {
                            if let index = parentTags.firstIndex(where: {$0.id == tag.id}) {
                                parentTags.remove(at: index)
                            }
                        }) {
                            Image(systemName: "minus")
                                .frame(minHeight: 0, maxHeight: .infinity)
                        }
                        .tint(.red)
                        .buttonStyle(.bordered)
                    }
                }
                Button(action: {
                    showTagParentSelector = true
                }) {
                    Label("Add Parent Tag", systemImage: "plus")
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
                .tint(.blue)
                .buttonStyle(.bordered)
                .sheet(isPresented: $showTagParentSelector) {
                    NavigationView {
                        ScrollView {
                            VStack {
                                ForEach(tags) { tag in
                                    Button(action: {
                                        parentTags.filter({$0.id == tagId}).count == 0 ? parentTags.append(tag) : ()
                                        showTagParentSelector = false
                                    }) {
                                        TagView(tag: tag, fullWidth: true)
                                    }
                                }
                            }
                            .padding(16)
                        }
                        .navigationTitle("Tags")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading){
                                Button(action: {
                                    showTagParentSelector = false
                                }) {
                                    Image(systemName: "chevron.backward")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

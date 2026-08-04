import SwiftUI

struct TagEditorParents: View {
    @Binding var parentTags: [Tag]
    @Binding var disambiguationId: Int?
    @State var showTagParentSelector: Bool = false
    var tagId: Int
    var tags: [Tag]
    
    func addParent(_ tag: Tag) {
        if parentTags.filter({$0.id == tagId}).isEmpty {
            parentTags.append(tag)
        }
        showTagParentSelector = false
    }
    
    var body: some View {
        List {
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
                    .swipeActions {
                        Button(role: .destructive, action: {
                            if let index = parentTags.firstIndex(where: {$0.id == tag.id}) {
                                parentTags.remove(at: index)
                            }
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
                  return 0
                }
            }
            Button(action: {
                showTagParentSelector = true
            }) {
                Label("Add Parent Tag", systemImage: "plus")
            }
            .sheet(isPresented: $showTagParentSelector) {
                TagSearch(tags: .constant(tags), selectAction: addParent, multiSelect: false, selected: [], closeButton: true)
            }
        }
        .listStyle(.plain)
    }
}

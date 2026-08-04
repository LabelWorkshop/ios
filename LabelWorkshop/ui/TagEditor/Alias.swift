import SwiftUI

struct TagEditorAlias: View {
    @Binding var aliases: [TagAlias]
    var tagId: Int
    
    var body: some View {
        List {
            ForEach($aliases){ $alias in
                TextField("Alias", text: $alias.name)
                    .swipeActions {
                        Button(role: .destructive, action: {
                            if let index = aliases.firstIndex(where: {$0.id == alias.id}) {
                                aliases.remove(at: index)
                            }
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            Button(action: {
                aliases.append(TagAlias(id: Int.random(in: (-9999)..<(-1)), name: "", tagId: tagId))
            }) {
                Label("Add Alias", systemImage: "plus")
            }
        }
        .listStyle(.plain)
    }
}







import SwiftUI

struct TagEditorAlias: View {
    @Binding var aliases: [TagAlias]
    var tagId: Int
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach($aliases){ $alias in
                    HStack {
                        TextField("Alias", text: $alias.name)
                        Button(role: .destructive, action: {
                            if let index = aliases.firstIndex(where: {$0.id == alias.id}) {
                                aliases.remove(at: index)
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
                    aliases.append(TagAlias(id: Int.random(in: (-9999)..<(-1)), name: "", tagId: tagId))
                }) {
                    Label("Add Alias", systemImage: "plus")
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
                .tint(.blue)
                .buttonStyle(.bordered)
            }
        }
    }
}







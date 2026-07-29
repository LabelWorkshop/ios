import SwiftUI

struct TagEditorGeneral: View {
    @Binding var name: String
    @Binding var shorthand: String
    @Binding var colors: TagColor
    @Binding var tagColors: TagColorManager
    @Binding var isCategory: Bool
    @Binding var isHidden: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            HStack {
                Text("Name")
                TextField("Name", text: $name)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
            HStack {
                Text("Shorthand")
                TextField("Shorthand", text: $shorthand)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
            NavigationLink {
                ColorSearch(tagColors: tagColors, colorSelectAction: { color in
                    colors = color
                })
            } label: {
                HStack {
                    Text("Color")
                    Text(colors.name)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            Toggle("Is Category?", isOn: $isCategory)
            Toggle("Is Hidden?", isOn: $isHidden)
        }
        .listStyle(.plain)
    }
}




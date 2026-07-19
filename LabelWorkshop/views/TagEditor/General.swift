import SwiftUI

struct TagEditorGeneral: View {
    @Binding var name: String
    @Binding var shorthand: String
    @Binding var colors: TagColor
    @Binding var tagColors: [TagColor]
    @Binding var isCategory: Bool
    @Binding var isHidden: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            TextField("Name", text: $name)
            TextField("Shorthand", text: $shorthand)
            NavigationLink {
                ScrollView {
                    VStack {
                        ForEach($tagColors) { tagColor in
                            Button(action: {
                                colors = tagColor.wrappedValue
                                dismiss()
                            }) {
                                TagPreView(name: tagColor.name, colors: tagColor, fullWidth: true)
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }
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




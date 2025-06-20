import SwiftUI

struct TagDetailsView: View {
    let tag: Tag
    
    @State private var name: String
    
    init(tag: Tag) {
        self.tag = tag
        self.name = tag.name
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                TagView(tag: tag)
                    .padding(.top, 50)
                    .padding(.bottom, 50)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.tertiarySystemFill))
                    .cornerRadius(8)
                TextField("Tag Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                HStack {
                    Button(action: {
                        do {
                            try tag.setColumn(column: Tag.nameColumn, value: self.name)
                        } catch {}
                    }) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Save")
                        }
                        .frame(
                            minWidth: 0,
                            maxWidth: .infinity
                        )
                    }.tint(.blue)
                    Button(role: .destructive, action: {
                        do {
                            try tag.delete() // Add confimation
                        } catch {}
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .frame(
                            minWidth: 0,
                            maxWidth: .infinity
                        )
                    }.tint(.red)
                }
                .controlSize(.large)
                .buttonStyle(.bordered)
            }.padding(16)
        }.navigationTitle(tag.name)
    }
}

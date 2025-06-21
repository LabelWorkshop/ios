import SwiftUI

struct TagDetailsView: View {
    let tag: Tag
    
    @State private var name: String
    @State private var shorthand: String
    @Environment(\.dismiss) private var dismiss
    
    init(tag: Tag) {
        self.tag = tag
        self.name = tag.name
        self.shorthand = tag.shorthand ?? ""
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                TagView(tag: tag)
                    .padding(.top, 50)
                    .padding(.bottom, 50)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.tertiarySystemFill))
                    .background(
                        Image("dots")
                            .opacity(0.3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 2)
                            .blur(radius: 14)
                            .opacity(0.6)
                    )
                    .cornerRadius(8)
                    .shadow(radius: 8)
                HStack {
                    TextBox(title: "Name", value: $name)
                    TextBox(title: "Shorthand", value: $shorthand)
                }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                HStack {
                    Button(action: {
                        do {
                            try tag.setColumn(column: Tag.nameColumn, value: self.name)
                            try tag.setColumn(column: Tag.shorthandColumn, value: self.shorthand)
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
                            dismiss()
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

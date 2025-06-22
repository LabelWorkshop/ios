import SwiftUI

struct TagDetailsView: View {
    let tag: Tag
    
    @State private var name: String
    @State private var shorthand: String
    @State private var colors: TagColor
    @State private var isCategory: Bool
    @State private var showTagColorSelector: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var tagColors: [TagColor]
    
    init(tag: Tag) {
        self.tag = tag
        self.name = tag.name
        self.shorthand = tag.shorthand ?? ""
        self.colors = tag.colors
        self.isCategory = tag.isCategory
        self.tagColors = tag.library.tagColors?.colors ?? []
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                TagPreView(
                    name: $name,
                    colors: $colors
                )
                    .padding(50)
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
                HStack{
                    VStack {
                        Text("Color").font(.caption2).frame(maxWidth: .infinity, alignment: .leading)
                        Button(action: {
                            showTagColorSelector.toggle()
                        }) {
                            TagPreView(name: $colors.name, colors: $colors, fullWidth: true)
                        }
                        .popover(isPresented: $showTagColorSelector) {
                            NavigationView {
                                ScrollView {
                                    VStack {
                                        ForEach($tagColors) { tagColor in
                                            Button(action: {
                                                colors = tagColor.wrappedValue
                                                showTagColorSelector = false
                                            }) {
                                                TagPreView(name: tagColor.name, colors: tagColor, fullWidth: true)
                                            }
                                        }
                                    }
                                    .padding(16)
                                }
                                .navigationTitle("Color")
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarLeading){
                                        Button(action: {
                                            showTagColorSelector = false
                                        }) {
                                            Image(systemName: "chevron.backward")
                                            Text("Back")
                                        }
                                    }
                                }
                            }
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    VStack {
                        Text("Is Category?").font(.caption2)
                        Toggle("Is Category?", isOn: $isCategory).labelsHidden()
                    }
                }
                HStack {
                    Button(action: {
                        do {
                            try tag.setColumn(column: Tag.nameColumn, value: self.name)
                            try tag.setColumn(column: Tag.shorthandColumn, value: self.shorthand)
                            try tag.setColumn(column: Tag.isCategoryColumn, value: self.isCategory)
                            try tag.setColor(self.colors)
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

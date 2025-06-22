import SwiftUI

struct TagDetailsView: View {
    let tag: Tag
    
    @State private var name: String
    @State private var shorthand: String
    @State private var colors: TagColor
    @State private var isCategory: Bool
    @State var aliases: [TagAlias]
    @State var parentTags: [Tag]
    @State private var showTagParentSelector: Bool = false
    @State private var showTagColorSelector: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var tagColors: [TagColor]
    
    init(tag: Tag) {
        self.tag = tag
        self.name = tag.realName
        self.shorthand = tag.shorthand ?? ""
        self.colors = tag.colors
        self.isCategory = tag.isCategory
        self.tagColors = tag.library.tagColors?.colors ?? []
        self.aliases = tag.getAliases()
        self.parentTags = tag.getParentTags()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 8) {
                        TagPreView(
                            name: $name,
                            colors: $colors
                        )
                        .shadow(color: colors.border, radius: 16)
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
                        )
                        .cornerRadius(8)
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
                        VStack {
                            Text("Aliases").font(.caption2).frame(maxWidth: .infinity, alignment: .leading)
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
                                    aliases.append(TagAlias(id: Int.random(in: (-9999)..<(-1)), name: "", tagId: tag.id))
                                }) {
                                    Label("New Alias", systemImage: "plus")
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                }
                                .tint(.blue)
                                .buttonStyle(.bordered)
                            }
                            .padding(8)
                            .background(Color(UIColor.tertiarySystemFill))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .cornerRadius(8)
                        }
                        VStack {
                            Text("Parent Tags").font(.caption2).frame(maxWidth: .infinity, alignment: .leading)
                            VStack {
                                ForEach($parentTags){ $tag in
                                    HStack {
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
                                    Label("Add Parent", systemImage: "plus")
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                }
                                .tint(.blue)
                                .buttonStyle(.bordered)
                                .popover(isPresented: $showTagParentSelector) {
                                    NavigationView {
                                        ScrollView {
                                            VStack {
                                                ForEach(Tag.fetchAll(library: tag.library)) { tag in
                                                    Button(action: {
                                                        parentTags.filter({$0.id == tag.id}).count == 0 ? parentTags.append(tag) : ()
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
                                                    Text("Back")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(8)
                            .background(Color(UIColor.tertiarySystemFill))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .cornerRadius(8)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 80)
                }.navigationTitle(tag.name)
                
                HStack {
                    Button(action: {
                        do {
                            try tag.setColumn(column: Tag.nameColumn, value: self.name)
                            try tag.setColumn(column: Tag.shorthandColumn, value: self.shorthand)
                            try tag.setColumn(column: Tag.isCategoryColumn, value: self.isCategory)
                            tag.setAliases(self.aliases)
                            try tag.setColor(self.colors)
                            tag.setParentTags(self.parentTags)
                        } catch {}
                        dismiss()
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
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 8)
        }
    }
}

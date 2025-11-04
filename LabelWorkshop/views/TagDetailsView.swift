import SwiftUI

struct TagDetailsView: View {
    let tag: Tag
    
    @State private var name: String
    @State private var shorthand: String
    @State private var colors: TagColor
    @State private var isCategory: Bool
    @State var aliases: [TagAlias]
    @State var parentTags: [Tag]
    @State var disambiguationId: Int?
    @State var disambiguationName: String?
    @State var displayName: String = ""
    @State private var showTagParentSelector: Bool = false
    @State private var showTagColorSelector: Bool = false
    @State private var tagDeleteConfirmation: Bool = false
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
                ScrollView {
                    VStack(spacing: 8) {
                        TagPreView(
                            name: $displayName,
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
                                Text("color").font(.caption2).frame(maxWidth: .infinity, alignment: .leading)
                                Button(action: {
                                    showTagColorSelector.toggle()
                                }) {
                                    TagPreView(name: $colors.name, colors: $colors, fullWidth: true)
                                }
                                .sheet(isPresented: $showTagColorSelector) {
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
                                        .navigationTitle("color")
                                        .toolbar {
                                            ToolbarItem(placement: .navigationBarLeading){
                                                Button(action: {
                                                    showTagColorSelector = false
                                                }) {
                                                    Image(systemName: "chevron.backward")
                                                    Text("back")
                                                }
                                            }
                                        }
                                    }
                                }
                            }.frame(maxWidth: .infinity, alignment: .leading)
                            VStack {
                                Text("tag.isCategory").font(.caption2)
                                Toggle("tag.isCategory", isOn: $isCategory).labelsHidden()
                            }.frame(maxHeight: .infinity, alignment: .top)
                        }
                        VStack {
                            Text("tag.aliases").font(.caption2).frame(maxWidth: .infinity, alignment: .leading)
                            VStack {
                                ForEach($aliases){ $alias in
                                    HStack {
                                        TextField("tag.alias", text: $alias.name)
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
                                    Label("tag.alias.add", systemImage: "plus")
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
                            Text("tag.parents").font(.caption2).frame(maxWidth: .infinity, alignment: .leading)
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
                                                Image(systemName: disambiguationId == tag.id ? "checkmark.square" : "square")
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
                                    Label("tag.parents.add", systemImage: "plus")
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                }
                                .tint(.blue)
                                .buttonStyle(.bordered)
                                .sheet(isPresented: $showTagParentSelector) {
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
                                        .navigationTitle("entry.tags")
                                        .toolbar {
                                            ToolbarItem(placement: .navigationBarLeading){
                                                Button(action: {
                                                    showTagParentSelector = false
                                                }) {
                                                    Image(systemName: "chevron.backward")
                                                    Text("back")
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
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing){
                        if #available(iOS 26.0, *) {
                            Button(role: .confirm, action: confirmEdits) {
                                Image(systemName: "checkmark")
                            }
                        } else {
                            Button(action: confirmEdits) {
                                Image(systemName: "checkmark")
                            }.tint(.blue)
                        }
                    }
                    ToolbarItem(placement: .bottomBar){
                        Button(role: .destructive, action: {
                            tagDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                        }.tint(.red)
                        .confirmationDialog(
                            Text("tag.delete.confirmation"),
                            isPresented: $tagDeleteConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button(role: .destructive, action: {
                                do {
                                    try tag.delete()
                                    tagDeleteConfirmation = false
                                    dismiss()
                                } catch {}
                            }) {
                                Text("tag.delete")
                            }
                        }
                    }
                }
        .onAppear {
            self.disambiguationId = tag.disambiguationId
            updateName()
        }
        .onChange(of: disambiguationId) { _ in
            self.disambiguationName = nil
            if let disambiguationId = disambiguationId {
                let tag: Tag? = Tag.fetch(library: tag.library, id: disambiguationId)
                if let tag = tag {
                    self.disambiguationName = tag.name
                }
            }
            updateName()
        }
        .onChange(of: name) { _ in
            updateName()
        }
    }
    
    func updateName() {
        var suffix = ""
        if let disambiguationName = disambiguationName {
            suffix = " (\(disambiguationName))"
        }
        self.displayName = "\(name)\(suffix)"
    }
    
    func confirmEdits() {
        do {
            try tag.setColumn(column: Tag.nameColumn, value: self.name)
            try tag.setColumn(column: Tag.shorthandColumn, value: self.shorthand)
            try tag.setColumn(column: Tag.isCategoryColumn, value: self.isCategory)
            try tag.setColumn(column: Tag.disambiguationIdColumn, value: self.disambiguationId)
            tag.setAliases(self.aliases)
            try tag.setColor(self.colors)
            tag.setParentTags(self.parentTags)
        } catch {}
        dismiss()
    }
}

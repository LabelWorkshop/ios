import SwiftUI

struct TagDetailsView: View {
    let tag: Tag
    let library: Library
    
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
    @State var tagDetailsTab = 0
    
    init(library: Library, tag: Tag) {
        self.tag = tag
        self.library = library
        self.name = tag.realName
        self.shorthand = tag.shorthand ?? ""
        self.colors = tag.colors
        self.isCategory = tag.isCategory
        self.tagColors = tag.library?.tagColors?.colors ?? []
        self.aliases = tag.getAliases()
        self.parentTags = self.library.tags.getParentTags(of: tag)
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
                .cornerRadius(40)
                Picker("", selection: $tagDetailsTab) {
                    Text("General").tag(0)
                    Text("Parent Tags").tag(1)
                    Text("Alias").tag(2)
                }.pickerStyle(SegmentedPickerStyle())
                if tagDetailsTab == 0 {
                    VStack {
                        HStack {
                            TextBox(title: "Name", value: $name)
                            TextBox(title: "Shorthand", value: $shorthand)
                        }
                        HStack{
                            VStack {
                                Text("Color").font(.caption2).frame(maxWidth: .infinity, alignment: .leading)
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
                            }.frame(maxHeight: .infinity, alignment: .top)
                        }
                    }
                } else if tagDetailsTab == 1 {
                    VStack {
                        Text("Parent Tags").font(.caption2).frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 8)
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
                                            Image(systemName: disambiguationId == tag.id ? "checkmark.circle" : "circle").font(.title)
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
                                Label("Add Parent Tag", systemImage: "plus")
                                    .frame(minWidth: 0, maxWidth: .infinity)
                            }
                            .tint(.blue)
                            .buttonStyle(.bordered)
                            .sheet(isPresented: $showTagParentSelector) {
                                NavigationView {
                                    ScrollView {
                                        VStack {
                                            ForEach(self.library.tags.all) { tag in
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
                    }
                } else if tagDetailsTab == 2 {
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
                                Label("Add Alias", systemImage: "plus")
                                    .frame(minWidth: 0, maxWidth: .infinity)
                            }
                            .tint(.blue)
                            .buttonStyle(.bordered)
                        }
                    }
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
                    Text("This tag and all references of it will be deleted."),
                    isPresented: $tagDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(role: .destructive, action: {
                        do {
                            try self.library.tags.delete(tag)
                            tagDeleteConfirmation = false
                            dismiss()
                        } catch {print(error)}
                    }) {
                        Text("Delete Tag")
                    }
                }
            }
        }
        .onAppear {
            self.parentTags = self.library.tags.getParentTags(of: tag)
            self.disambiguationId = tag.disambiguationId
            updateName()
        }
        .onChange(of: disambiguationId) { _ in
            self.disambiguationName = nil
            if let disambiguationId = disambiguationId {
                let tag: Tag? = self.library.tags.getById(id: disambiguationId)
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
            try tag.setColumn(column: TagsTable.name, value: self.name)
            try tag.setColumn(column: TagsTable.shorthand, value: self.shorthand)
            try tag.setColumn(column: TagsTable.isCategory, value: self.isCategory)
            try tag.setColumn(column: TagsTable.disambiguationId, value: self.disambiguationId)
            tag.setAliases(self.aliases)
            try tag.setColor(self.colors)
            self.library.tags.setParentTags(tag: self.tag, parentTags: self.parentTags)
        } catch {print(error)}
        dismiss()
    }
}

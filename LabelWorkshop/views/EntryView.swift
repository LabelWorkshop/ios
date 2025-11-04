import SwiftUI
import Flow

struct EntryView: View {
    let entry: Entry
    @State var tags: [Tag] = []
    @State var fields: [Field] = []
    @State var showTagSelector: Bool = false
    @State var showFieldTypeSelector: Bool = false
    
    init(entry: Entry) {
        self.entry = entry
    }
    
    var body: some View {
            ScrollView {
                VStack(spacing: 8) {
                    EntryPreView(entry: entry)
                    Text(entry.path).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                    VStack(spacing: 8) {
                        Text("entry.tags").font(.title2).frame(maxWidth: .infinity, alignment: .leading)
                        HFlow {
                            ForEach($tags){ $tag in
                                Menu {
                                    Button(role: .destructive, action: {
                                        self.entry.removeTag(tag)
                                        self.tags = entry.getTags()
                                    }) {
                                        Label("remove", systemImage: "minus")
                                    }
                                } label: {
                                    TagView(tag: tag)
                                }
                                .buttonStyle(.plain)
                            }
                            Button(action: {
                                showTagSelector = true
                            }) {
                                Image(systemName: "plus")
                            }
                            .padding(10)
                            .background(Color(UIColor.tertiarySystemFill))
                            .tint(.gray)
                            .containerShape(Capsule())
                            .sheet(isPresented: $showTagSelector) {
                                NavigationView {
                                    ScrollView {
                                        VStack {
                                            ForEach(Tag.fetchAll(library: self.entry.library)) { tag in
                                                Button(action: {
                                                    tags.filter{ $0.id == tag.id }.count == 0 ? self.entry.addTag(tag) : ()
                                                    tags.append(tag)
                                                    showTagSelector = false
                                                }) {
                                                    TagView(tag: tag, fullWidth: true)
                                                }
                                            }
                                        }
                                        .padding(16)
                                    }
                                    .toolbar {
                                        ToolbarItem(placement: .navigationBarLeading){
                                            Button(action: {
                                                showTagSelector = false
                                            }) {
                                                Image(systemName: "chevron.backward")
                                                Text("back")
                                            }
                                        }
                                    }
                                }
                            }
                        }.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    }
                    VStack(spacing: 8) {
                        Text("entry.fields").font(.title2).frame(maxWidth: .infinity, alignment: .leading)
                        ForEach($fields){ $field in
                            VStack {
                                Text(field.name).font(.caption2).frame(maxWidth: .infinity, alignment: .leading)
                                HStack {
                                    TextField(field.name, text: $field.text)
                                    Button(role: .destructive, action: {
                                        do {
                                            try entry.deleteField($field.id)
                                            if let index = fields.firstIndex(where: { $0.id == $field.id }) {
                                                fields.remove(at: index)
                                            }
                                        } catch {}
                                    }) {
                                        Image(systemName: "minus")
                                            .frame(minHeight: 0, maxHeight: .infinity)
                                    }
                                    .tint(.red)
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                        Button(action: {
                            showFieldTypeSelector = true
                        }) {
                            Label("entry.fields.add", systemImage: "plus").frame(maxWidth: .infinity, alignment: .center)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        .cornerRadius(8)
                        .sheet(isPresented: $showFieldTypeSelector) {
                            NavigationView {
                                ScrollView {
                                    VStack {
                                        ForEach(entry.library.fieldTypes) { fieldType in
                                            if fieldType.type != "DATETIME" {
                                                Button(action: {
                                                    if let field = entry.addField(fieldType.key) {
                                                        fields.append(field)
                                                    }
                                                    showFieldTypeSelector = false
                                                }) {
                                                    TagPreView(
                                                        name: .constant(fieldType.name),
                                                        colors: .constant(TagColor.none),
                                                        fullWidth: true
                                                    )
                                                }
                                            }
                                        }
                                    }
                                    .padding(16)
                                }
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarLeading){
                                        Button(action: {
                                            showFieldTypeSelector = false
                                        }) {
                                            Image(systemName: "chevron.backward")
                                            Text("back")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }.padding(16)
                .padding(.bottom, 80)
            }.navigationTitle(entry.path)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                ShareLink(item: entry.fullPath!, message: Text(entry.path)) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.flexible, placement: .bottomBar)
            }
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: {
                    if let tag = Tag.fetch(library: entry.library, id: 1) {
                        if tags.filter({$0.id == tag.id}).isEmpty {
                            self.entry.addTag(tag)
                            tags.append(tag)
                        } else {
                            self.entry.removeTag(tag)
                            self.tags = entry.getTags()
                        }
                    }
                }) {
                    Image(systemName: tags.filter{ $0.id == 1 }.isEmpty ? "star": "star.fill")
                }
                .tint(.yellow)
                Button(action: {
                    if let tag = Tag.fetch(library: entry.library, id: 0) {
                        if tags.filter({$0.id == tag.id}).isEmpty {
                            self.entry.addTag(tag)
                            tags.append(tag)
                        } else {
                            self.entry.removeTag(tag)
                            self.tags = entry.getTags()
                        }
                    }
                }) {
                    Image(systemName: tags.filter{ $0.id == 0 }.isEmpty ? "archivebox": "archivebox.fill")
                }
                .tint(.red)
            }
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.flexible, placement: .bottomBar)
            }
            ToolbarItem(placement: .bottomBar) {
                Button(role: .destructive, action: {
                    do {
                        try FileManager.default.removeItem(at: entry.fullPath!)
                        entry.delete()
                    } catch {}
                }) {
                    Image(systemName: "trash")
                }
            }
        }.onAppear {
            self.tags = entry.getTags()
            self.fields = entry.getFields()
        }
    }
}

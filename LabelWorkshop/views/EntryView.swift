import SwiftUI
import Flow

struct EntryView: View {
    let entry: Entry
    @State var tags: [Tag] = []
    @State var fields: [Field] = []
    @State var showTagSelector: Bool = false
    @State var showFieldTypeSelector: Bool = false
    @State var fullScreen: Bool = false
    
    init(entry: Entry) {
        self.entry = entry
    }
    
    func addTag (_ tag: Tag) {
        tags.filter { $0.id == tag.id }.count == 0 ? self.entry.tags.add(tag) : ()
        tags.append(tag)
        showTagSelector = false
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Button {
                    fullScreen = true
                } label: {
                    EntryPreView(entry: entry)
                }
                Text(entry.path).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 8) {
                    Text("Tags").font(.title2).frame(maxWidth: .infinity, alignment: .leading)
                    HFlow {
                        ForEach(Tag.getNoCategoryTags(library: self.entry.library, tags: self.tags)) { tag in
                            Menu {
                                Button(role: .destructive, action: {
                                    self.entry.tags.remove(tag)
                                    self.tags = entry.tags.all
                                }) {
                                    Label("Remove", systemImage: "minus")
                                }
                            } label: {
                                TagView(tag: tag)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    ForEach(Tag.getAllCategories(library: self.entry.library, tags: self.tags), id: \.parent.id) { category in
                        Text(category.parent.name).font(.title2).frame(maxWidth: .infinity, alignment: .leading)
                        HFlow {
                            ForEach(category.children) { tag in
                                Menu {
                                    Button(role: .destructive, action: {
                                        self.entry.tags.remove(tag)
                                        self.tags = entry.tags.all
                                    }) {
                                        Label("Remove", systemImage: "minus")
                                    }
                                } label: {
                                    TagView(tag: tag)
                                }
                                .buttonStyle(.plain)
                            }
                        }.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    }
                    Button(action: {
                        showTagSelector = true
                    }) {
                        Label("Add Tags", systemImage: "plus").frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .containerShape(Capsule())
                    .sheet(isPresented: $showTagSelector) {
                        TagSearch(library: self.entry.library, tags: .constant(entry.library.tags.all), selectAction: addTag, multiSelect: false, selected: [], closeButton: true)
                    }
                }
                VStack(spacing: 8) {
                    Text("Fields").font(.title2).frame(maxWidth: .infinity, alignment: .leading)
                    ForEach($fields) { $field in
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
                                    } catch {print(error)}
                                }) {
                                    Image(systemName: "minus")
                                        .frame(minHeight: 0, maxHeight: .infinity)
                                }
                                .tint(.red)
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    Menu {
                        ForEach(entry.library.fieldTypes) { fieldType in
                            Button(action: {
                                if let field = entry.addField(fieldType) {
                                    fields.append(field)
                                }
                            }) {
                                Text(fieldType.name)
                            }
                        }
                    } label: {
                        Label("Add Field", systemImage: "plus").frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .cornerRadius(8)
                }
            }
            .padding(16)
            .padding(.bottom, 80)
        }
        .navigationTitle(entry.path)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ShareLink(item: entry.fullPath!, message: Text(entry.path)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive, action: {
                        do {
                            try FileManager.default.removeItem(at: entry.fullPath!)
                            self.entry.library.entries.delete(entry)
                        } catch {print(error)}
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: {
                    if let tag = entry.library.tags.getById(id: 1) {
                        if tags.filter({ $0.id == tag.id }).isEmpty {
                            self.entry.tags.add(tag)
                            tags.append(tag)
                        } else {
                            self.entry.tags.remove(tag)
                            self.tags = entry.tags.all
                        }
                    }
                }) {
                    Image(systemName: tags.filter { $0.id == 1 }.isEmpty ? "star" : "star.fill")
                }
                .tint(.yellow)
                Button(action: {
                    if let tag = entry.library.tags.getById(id: 0) {
                        if tags.filter({ $0.id == tag.id }).isEmpty {
                            self.entry.tags.add(tag)
                            tags.append(tag)
                        } else {
                            self.entry.tags.remove(tag)
                            self.tags = entry.tags.all
                        }
                    }
                }) {
                    Image(systemName: tags.filter { $0.id == 0 }.isEmpty ? "archivebox" : "archivebox.fill")
                }
                .tint(.red)
            }
        }
        .onAppear {
            self.tags = entry.tags.all
            self.fields = entry.getFields()
        }
        .fullScreenCover(isPresented: $fullScreen) {
            Button{
                fullScreen = false
            } label: {
                EntryPreView(entry: self.entry, square: false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
        }
    }
}

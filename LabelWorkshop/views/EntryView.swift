import SwiftUI
import Flow

struct TagBoxTag: View {
    let entry: Entry
    let tag: Tag
    
    var body: some View {
        Menu {
            Button(role: .destructive, action: {
                self.entry.tags.remove(tag)
                // self.tags = entry.tags.all
            }) {
                Label("Remove", systemImage: "minus")
            }
        } label: {
            TagView(tag: tag)
        }
        .buttonStyle(.plain)
    }
}

struct EntryView: View {
    @State var entry: Entry
    @State var fields: [Field] = []
    @State var showTagSelector: Bool = false
    @State var showFieldTypeSelector: Bool = false
    @State var fullScreen: Bool = false
    @State var deletionError: Bool = false
    
    init(entry: Entry) {
        self.entry = entry
    }
    
    func addTag (_ tag: Tag) {
        if entry.tags.all.filter({ $0.id == tag.id }).isEmpty {
            self.entry.tags.add(tag)
        }
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
                Text("Tags").font(.headline).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                HFlow {
                    ForEach(Tag.getNoCategoryTags(library: self.entry.library, tags: self.entry.tags.all)) { tag in
                        TagBoxTag(entry: entry, tag: tag)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                ForEach(Tag.getAllCategories(library: self.entry.library, tags: self.entry.tags.all), id: \.parent.id) { category in
                    Text(category.parent.name).font(.headline).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                    HFlow {
                        ForEach(category.children) { tag in
                            TagBoxTag(entry: entry, tag: tag)
                        }
                    }.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                }
                Text("Fields").font(.headline).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                ForEach($fields) { $field in
                    HStack {
                        Text(field.name)
                        TextField(field.name, text: $field.text)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                        Button(role: .destructive, action: {
                            do {
                                try entry.deleteField($field.id)
                                if let index = fields.firstIndex(where: { $0.id == $field.id }) {
                                    fields.remove(at: index)
                                }
                            } catch {print(error)}
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .font(.title)
                        }
                        .tint(.red)
                    }
                }
            }
            .padding(.horizontal)
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
                            try self.entry.library.entries.delete(entry)
                            try FileManager.default.removeItem(at: entry.fullPath!)
                        } catch {
                            self.deletionError = true
                        }
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
            
            ToolbarItem(placement: .bottomBar) {
                Menu {
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
                        Label("Field", systemImage: "character.textbox")
                    }
                    Button {
                        showTagSelector = true
                    } label: {
                        Label("Tag", systemImage: "tag")
                    }
                } label: {
                    Button {
                        
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(ProminentButtonStyle())
                }
                .sheet(isPresented: $showTagSelector) {
                    TagSearch(library: self.entry.library, tags: .constant(entry.library.tags.all), selectAction: addTag, multiSelect: false, selected: [], closeButton: true)
                }
            }
            
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .bottomBar)
            }
            
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: {
                    if let tag = entry.library.tags.getById(id: 1) {
                        if entry.tags.all.filter({ $0.id == tag.id }).isEmpty {
                            self.entry.tags.add(tag)
                        } else {
                            self.entry.tags.remove(tag)
                        }
                    }
                }) {
                    Image(systemName: entry.tags.all.filter { $0.id == 1 }.isEmpty ? "star" : "star.fill")
                }
                .tint(.yellow)
                Button(action: {
                    if let tag = entry.library.tags.getById(id: 0) {
                        if entry.tags.all.filter({ $0.id == tag.id }).isEmpty {
                            self.entry.tags.add(tag)
                        } else {
                            self.entry.tags.remove(tag)
                        }
                    }
                }) {
                    Image(systemName: entry.tags.all.filter { $0.id == 0 }.isEmpty ? "archivebox" : "archivebox.fill")
                }
                .tint(.red)
            }
        }
        .onAppear {
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
        .alert("Delete Failed", isPresented: $deletionError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("An error occured while trying to delete this entry.")
        }
    }
}

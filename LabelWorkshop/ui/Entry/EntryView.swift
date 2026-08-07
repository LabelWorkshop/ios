import SwiftUI
import Flow

struct TagBoxTag: View {
    let entry: Entry
    let tag: Tag
    
    @State var error: Bool = false
    
    var body: some View {
        Menu {
            Button(role: .destructive, action: {
                do {
                    guard let tags = entry.tags else { throw EntryManagerError.insertionFailed }
                    try tags.remove(tag)
                } catch {
                    self.error = true
                }
            }) {
                Label("Remove", systemImage: "minus")
            }
        } label: {
            TagView(tag: tag)
        }
        .buttonStyle(.plain)
        .alert("Unknown Error", isPresented: $error) {} message: {
            Text("Something went wrong.")
        }
    }
}

struct TagToggleButton: View {
    @Binding var entry: Entry
    let tag: Tag
    let untoggledIcon: String
    let toggledIcon: String
    let name: String
    let tint: Color
    
    @State var error: Bool = false
    
    var isOn: Bool {
        guard let tags = entry.tags else { return false }
        return tags.all.contains{ $0.id == tag.id }
    }
    
    var body: some View {
        Button(action: {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            do {
                guard let tags = entry.tags else { throw EntryManagerError.insertionFailed }
                try withTransaction(transaction) {
                    if isOn {
                        try tags.remove(tag)
                    } else {
                        try tags.add(tag)
                    }
                }
            } catch {
                self.error = true
            }
        }) {
            Label(NSLocalizedString(name, comment: ""), systemImage: isOn ? toggledIcon : untoggledIcon)
        }
        .tint(tint)
        .alert("Unknown Error", isPresented: $error) {} message: {
            Text("Something went wrong.")
        }
    }
}

struct EntryFavoriteButton: View {
    @Binding var entry: Entry
    var tag: Tag?
    
    init(entry: Binding<Entry>) {
        self._entry = entry
        self.tag = self.entry.library.tags.getById(id: 1)
    }
    
    var body: some View {
        if let tag = tag {
            TagToggleButton(
                entry: $entry,
                tag: tag,
                untoggledIcon: "star",
                toggledIcon: "star.fill",
                name: "Favorite",
                tint: .yellow
            )
        }
    }
}

struct EntryArchiveButton: View {
    @Binding var entry: Entry
    var tag: Tag?
    
    init(entry: Binding<Entry>) {
        self._entry = entry
        self.tag = self.entry.library.tags.getById(id: 0)
    }
    
    var body: some View {
        if let tag = tag {
            TagToggleButton(
                entry: $entry,
                tag: tag,
                untoggledIcon: "archivebox",
                toggledIcon: "archivebox.fill",
                name: "Archive",
                tint: .red
            )
        }
    }
}

struct EntryDeleteButton: View {
    @Binding var entry: Entry
    @Binding var deletionError: Bool
    
    var body: some View {
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
    }
}

struct EntryShareButton: View {
    @Binding var entry: Entry
    
    var body: some View {
        if let url = entry.fullPath {
            ShareLink(item: url, message: Text(entry.path)) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        } else {
            Button {} label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .disabled(true)
        }
    }
}

struct EntryView: View {
    @State var entry: Entry
    @State var showTagSelector: Bool = false
    @State var showFieldTypeSelector: Bool = false
    @State var fullScreen: Bool = false
    @State var deletionError: Bool = false
    @State var error: Bool = false
    @State var tagInitError: Bool = false
    @State var tagInitErrorDisable: Bool = false
    
    init(entry: Entry) {
        self.entry = entry
    }
    
    func addTag (_ tag: Tag) {
        do {
            guard let tags = entry.tags else { throw EntryManagerError.insertionFailed }
            if tags.all.filter({ $0.id == tag.id }).isEmpty {
                try tags.add(tag)
            }
            showTagSelector = false
        } catch {
            self.error = true
        }
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
                    ForEach(Tag.getNoCategoryTags(library: self.entry.library, tags: self.entry.tags?.all ?? [])) { tag in
                        TagBoxTag(entry: entry, tag: tag)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                ForEach(Tag.getAllCategories(library: self.entry.library, tags: self.entry.tags?.all ?? []), id: \.parent.id) { category in
                    Text(category.parent.name).font(.headline).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                    HFlow {
                        ForEach(category.children) { tag in
                            TagBoxTag(entry: entry, tag: tag)
                        }
                    }.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                }
                
                if let fields = entry.fields {
                    Text("Fields").font(.headline).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(fields.textFields) { field in
                        HStack {
                            Text(field.name)
                            TextField(field.name, text: Binding<String>(
                                get: { field.text },
                                set: { newValue in field.text = newValue }
                            ))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                            Button(role: .destructive) {
                                do {
                                    try withAnimation(.easeInOut(duration: 0.25)) {
                                        try fields.remove(field: field)
                                    }
                                } catch { print(error) }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .font(.title)
                            }
                            .tint(.red)
                        }
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .move(edge: .leading)
                        ))
                    }.animation(.easeInOut(duration: 0.25), value: fields.fields.map(\.id))
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle(entry.path)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    EntryShareButton(entry: $entry)
                    EntryDeleteButton(entry: $entry, deletionError: $deletionError)
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
            
            ToolbarItem(placement: .bottomBar) {
                Menu {
                    Menu {
                        if let fieldTemplates = entry.library.fieldTemplates {
                            // TODO: Move the button code into a view
                            Section("Text Fields") {
                                ForEach(fieldTemplates.texts) { fieldTemplate in
                                    Button(action: {
                                        do {
                                            if let fields = entry.fields {
                                                _ = try fields.add(fieldTemplate)
                                            }
                                        } catch {print(error)}
                                    }) {
                                        Text(fieldTemplate.name)
                                    }
                                }
                            }
                            Section("Date Fields") {
                                ForEach(fieldTemplates.dates) { fieldTemplate in
                                    Button(action: {
                                        do {
                                            if let fields = entry.fields {
                                                _ = try fields.add(fieldTemplate)
                                            }
                                        } catch {print(error)}
                                    }) {
                                        Text(fieldTemplate.name)
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Field", systemImage: "character.textbox")
                    }
                    .disabled(entry.library.fieldTemplates == nil)
                    Button {
                        showTagSelector = true
                    } label: {
                        Label("Tag", systemImage: "tag")
                    }
                    .disabled(tagInitErrorDisable)
                } label: {
                    Button {
                        
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(ProminentButtonStyle())
                }
                .sheet(isPresented: $showTagSelector) {
                    TagSearch(library: self.entry.library, tags: .constant(entry.library.tags.tags), selectAction: addTag, multiSelect: false, selected: [], closeButton: true)
                }
            }
            
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.fixed, placement: .bottomBar)
            }
            
            ToolbarItemGroup(placement: .bottomBar) {
                EntryFavoriteButton(entry: $entry)
                    .disabled(tagInitErrorDisable)
                EntryArchiveButton(entry: $entry)
                    .disabled(tagInitErrorDisable)
            }
        }
        .onAppear {
            if entry.tags == nil {
                self.tagInitError = true
                self.tagInitErrorDisable = true
            }
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
        .alert("Delete Failed", isPresented: $deletionError) {} message: {
            Text("An error occured while trying to delete this entry.")
        }
        .alert("Unknown Error", isPresented: $error) {} message: {
            Text("Something went wrong.")
        }
        .alert("Tag Initialization Error", isPresented: $tagInitError) {} message: {
            Text("An error occured while trying to get the tags for this entry.")
        }
    }
}


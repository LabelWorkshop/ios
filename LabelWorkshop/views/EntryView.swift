import SwiftUI
import Flow

struct EntryView: View {
    let entry: Entry
    @State var tags: [Tag]
    @State var fields: [Field]
    @State var showTagSelector: Bool = false
    
    init(entry: Entry) {
        self.entry = entry
        self.tags = entry.getTags()
        self.fields = entry.getFields()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if let image = loadImage(for: entry) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                } else {
                    Text("No preview available")
                }
                HStack {
                    if let fullPath: URL = entry.fullPath {
                        ShareLink(item: fullPath, message: Text(entry.path)) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .frame(
                                minWidth: 0,
                                maxWidth: .infinity
                            )
                        }.tint(.blue)
                        Button(role: .destructive, action: {
                            do {
                                try FileManager.default.removeItem(at: entry.fullPath!)
                                entry.delete()
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
                }
                .controlSize(.large)
                .buttonStyle(.bordered)
                Text(entry.path).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 8) {
                    Text("Tags").font(.title2).frame(maxWidth: .infinity, alignment: .leading)
                    HFlow {
                        ForEach($tags){ $tag in
                            TagView(tag: tag)
                        }
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
                                            Text("Back")
                                        }
                                    }
                                }
                            }
                        }
                        Button(action: {
                            showTagSelector = true
                        }) {
                            Image(systemName: "plus")
                        }
                        .padding(10)
                        .background(Color(UIColor.tertiarySystemFill))
                        .tint(.gray)
                        .cornerRadius(8)
                    }.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                }.padding(8).background(Color(UIColor.secondarySystemFill)).cornerRadius(8)
                VStack(spacing: 8) {
                    Text("Fields").font(.title2).frame(maxWidth: .infinity, alignment: .leading)
                    ForEach($fields){ $field in
                        VStack {
                            Text(field.name).font(.caption2).frame(maxWidth: .infinity, alignment: .leading)
                            TextField(field.name, text: $field.text)
                        }
                    }
                }.padding(8).background(Color(UIColor.secondarySystemFill)).cornerRadius(8)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }.padding(16)
        }.navigationTitle(entry.path)
    }
}

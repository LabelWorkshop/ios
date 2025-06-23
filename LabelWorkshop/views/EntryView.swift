import SwiftUI

struct EntryView: View {
    let entry: Entry
    @State var tags: [Tag]
    @State var showTagSelector: Bool = false
    
    init(entry: Entry) {
        self.entry = entry
        self.tags = entry.getTags()
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
                Text(entry.path).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 8) {
                    Text("Tags").font(.title2).frame(maxWidth: .infinity, alignment: .leading)
                    HStack {
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
            }.padding(16)
        }.navigationTitle(entry.path)
    }
}

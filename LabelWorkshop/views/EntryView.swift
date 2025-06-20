import SwiftUI

struct EntryView: View {
    let entry: Entry
    
    init(entry: Entry) {
        self.entry = entry
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
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                            .frame(
                                minWidth: 0,
                                maxWidth: .infinity
                            )
                        }.tint(.red).disabled(true)
                    }
                }
                .controlSize(.large)
                .buttonStyle(.bordered)
                Text(entry.path).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 8) {
                    Text("Tags").font(.title2).frame(maxWidth: .infinity, alignment: .leading)
                    HStack {
                        ForEach(entry.getTags(), id: \.id){ tag in
                            TagView(tag: tag)
                        }
                    }.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                }.padding(8).background(Color(UIColor.secondarySystemFill)).cornerRadius(8)
            }.padding(16)
        }.navigationTitle(entry.path)
    }
}

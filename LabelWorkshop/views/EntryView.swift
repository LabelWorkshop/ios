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
                }
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

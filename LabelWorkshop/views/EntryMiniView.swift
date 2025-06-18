import SwiftUI

struct EntryMiniView: View {
    let entry: Entry
    
    init(entry: Entry) {
        self.entry = entry
    }
    
    var body: some View {
        NavigationLink(destination: EntryView(entry: entry)){
            VStack(spacing: 0) {
                if let image = loadImage(for: entry) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            minWidth: 0,
                            maxWidth: .infinity,
                            minHeight: 0,
                            maxHeight: .infinity
                        )
                        .aspectRatio(1 / 1, contentMode: .fit)
                        .clipShape(Rectangle())
                        .cornerRadius(8)
                }
                Text(entry.path)
                    .font(.caption)
                    .lineLimit(1)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color(UIColor.label))
            }.background(Color(UIColor.secondarySystemFill)).cornerRadius(8)
        }
    }
}

import SwiftUI

struct EntryMiniView: View {
    let entry: Entry
    
    init(entry: Entry) {
        self.entry = entry
    }
    
    var body: some View {
        NavigationLink(destination: EntryView(entry: entry).id(entry.id)){
            VStack(spacing: 0) {
                EntryPreView(entry: entry, square: true)
                Text(entry.path)
                    .font(.caption)
                    .lineLimit(1)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color(UIColor.label))
            }.background(Color(UIColor.secondarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
}

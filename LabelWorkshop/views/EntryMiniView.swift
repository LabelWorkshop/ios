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
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(UIColor.secondarySystemBackground), lineWidth: 1)
                )
                Text(entry.fullPath?.lastPathComponent ?? entry.path)
                    .font(.caption)
                    .lineLimit(1)
                    .padding(EdgeInsets(top: 8, leading: 2, bottom: 4, trailing: 2))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(Color(UIColor.label))
            }
        }
    }
}

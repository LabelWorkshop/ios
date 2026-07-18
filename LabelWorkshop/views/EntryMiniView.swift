import SwiftUI

struct EntryMiniView: View {
    let entry: Entry
    @Binding var namesShown: Bool
    
    init(entry: Entry, namesShown: Binding<Bool>) {
        self.entry = entry
        self._namesShown = namesShown
    }
    
    var body: some View {
        NavigationLink(destination: EntryView(entry: entry).id(entry.id)){
            VStack(spacing: 0) {
                EntryPreView(entry: entry, square: true)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: namesShown ? 8 : 0))
                .overlay(
                    RoundedRectangle(cornerRadius: namesShown ? 8 : 0)
                        .stroke(Color(UIColor.secondarySystemBackground), lineWidth: namesShown ? 1 : 0)
                )
                if namesShown {
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
}

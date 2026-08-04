import SwiftUI

struct EntryContextMenu: View {
    @Binding var entry: Entry
    @Binding var deletionError: Bool
    
    var body: some View {
        EntryFavoriteButton(entry: $entry)
        EntryArchiveButton(entry: $entry)
        
        Divider()
        
        EntryShareButton(entry: $entry)
        EntryDeleteButton(entry: $entry, deletionError: $deletionError)
    }
}

struct EntryMiniView: View {
    @Binding var entry: Entry
    @Binding var namesShown: Bool
    @Binding var disabled: Bool
    @State var deletionError: Bool = false
    
    init(entry: Binding<Entry>, namesShown: Binding<Bool>) {
        self._entry = entry
        self._namesShown = namesShown
        self._disabled = .constant(false)
    }
    
    init(entry: Binding<Entry>, namesShown: Binding<Bool>, disabled: Binding<Bool>) {
        self._entry = entry
        self._namesShown = namesShown
        self._disabled = disabled
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
        .disabled(disabled)
        .contextMenu {
            EntryContextMenu(entry: $entry, deletionError: $deletionError)
        }
        .alert("Delete Failed", isPresented: $deletionError) {
        } message: {
            Text("An error occured while trying to delete this entry.")
        }
    }
}

import SwiftUI

func loadImage(for entry: Entry) -> UIImage? {
    guard let path = entry.fullPath else { return nil }
    guard let bookmark = entry.library.bookmark else { return nil }
    guard bookmark.startAccessingSecurityScopedResource() else { return nil }
    defer { bookmark.stopAccessingSecurityScopedResource() }
    if let data = try? Data(contentsOf: path) {
        let uiImage = UIImage(data: data)
        return uiImage
    }
    return nil
}

struct EntryPreView: View {
    public var entry: Entry
    public var square: Bool = false
    
    var body: some View {
        if let image = loadImage(for: entry) {
            if square {
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
                
            } else {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
            }
        } else {
            LazyVStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                Text("entry.previewUnavailable")
                    .foregroundStyle(Color(UIColor.label))
            }
            .symbolRenderingMode(.multicolor)
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity
            )
        }
    }
}

import SwiftUI
import AVKit

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

struct VideoPlayerContainer: UIViewControllerRepresentable {
    let entry: Entry
    let square: Bool
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: entry.fullPath!)
        player.isMuted = true
        let controller = AVPlayerViewController()
        controller.player = player
        if square {
            controller.showsPlaybackControls = false
            player.pause()
            player.seek(to: .zero)
            controller.allowsVideoFrameAnalysis = false
        } else {
            player.play()
        }
        controller.videoGravity = .resizeAspectFill
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

struct EntryPreView: View {
    public var entry: Entry
    public var square: Bool = false
    
    init(entry: Entry, square: Bool = false) {
        self.entry = entry
        self.square = square
    }
    
    var body: some View {
        Group {
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
                    
                } else {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
            } else if entry.path.hasSuffix(".mov") ||
                        entry.path.hasSuffix(".mp4") ||
                        entry.path.hasSuffix(".m4v") ||
                        entry.path.hasSuffix(".3gp")
            {
                VideoPlayerContainer(entry: entry, square: square)
                    .scaledToFill()
            }
            else {
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
        .clipped()
        .cornerRadius(8)
    }
}

import SwiftUI
import AVKit

func loadImage(for entry: Entry, thumbnail: Bool = false) -> UIImage? {
    guard let path = entry.fullPath else { return nil }
    guard let bookmark = entry.library.bookmark else { return nil }
    guard bookmark.startAccessingSecurityScopedResource() else { return nil }
    defer { bookmark.stopAccessingSecurityScopedResource() }
    if let data = try? Data(contentsOf: path) {
        let uiImage = UIImage(data: data)
        if thumbnail {
            let thumbnail = uiImage?.preparingThumbnail(of: CGSize(width: 300, height: 300))
            return thumbnail
        }
        return uiImage
    }
    return nil
}

func getVideoThumbnail(url: URL) -> UIImage? {
    let asset = AVURLAsset(url: url)

    let assetIG = AVAssetImageGenerator(asset: asset)
    assetIG.appliesPreferredTrackTransform = true
    assetIG.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels
    assetIG.maximumSize = CGSize(width: 300, height: 300)

    let cmTime = CMTime(seconds: 0, preferredTimescale: 60)
    let thumbnailImageRef: CGImage
    do {
        thumbnailImageRef = try assetIG.copyCGImage(at: cmTime, actualTime: nil)
    } catch {
        return nil
    }

    return UIImage(cgImage: thumbnailImageRef)
}

struct VideoPlayerContainer: UIViewControllerRepresentable {
    let entry: Entry
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: entry.fullPath!)
        let controller = AVPlayerViewController()
        controller.player = player
        player.isMuted = true
        player.play()
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
            if let image = loadImage(for: entry, thumbnail: square) {
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
                if square {
                    if let thumbnail = getVideoThumbnail(url: entry.fullPath!) {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(
                                minWidth: 0,
                                maxWidth: .infinity,
                                minHeight: 0,
                                maxHeight: .infinity
                            )
                            .aspectRatio(1 / 1, contentMode: .fit)
                    }
                } else {
                    VideoPlayerContainer(entry: entry)
                        .scaledToFill()
                }
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
                .aspectRatio(1/1, contentMode: .fill)
                .background(Color(UIColor.secondarySystemBackground))
            }
        }
        .clipped()
        .cornerRadius(8)
    }
}

import SwiftUI
import AVKit
import Foundation

func loadImage(for entry: Entry, thumbnail: Bool = false) async -> UIImage? {
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

func getVideoThumbnail(url: URL) async -> UIImage? {
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
    var ext: String?
    var isVideo: Bool
    var isImage: Bool
    @State var image: UIImage? = nil
    
    init(entry: Entry, square: Bool = false) {
        self.entry = entry
        self.square = square
        self.ext = entry.path.split(separator: ".").last?.lowercased()
        self.isVideo = ["mov","mp4","m4v","3gp"].contains(self.ext)
        self.isImage = UTType(filenameExtension: self.entry.fullPath?.pathExtension ?? "")?.conforms(to: .image) ?? false
    }
    
    var body: some View {
        Group {
            if !FileManager.default.fileExists(atPath: entry.fullPath!.path) {
                Image(systemName: "link")
                    .font(.system(size: 32))
                    .frame(
                        minWidth: 0,
                        maxWidth: .infinity,
                        minHeight: 0,
                        maxHeight: .infinity
                    )
                    .aspectRatio(1/1, contentMode: .fill)
                    .background(Color(UIColor.secondarySystemBackground))
                    .tint(.red)
            }
            else if self.isVideo && !square {
                VideoPlayerContainer(entry: entry)
                    .scaledToFill()
            }
            else if let image {
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
            }
            else {
                LazyVStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                    Text("No preview available")
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
        .task {
            if !(isImage || isVideo) {
                return
            }
            let cacheName = "\(self.entry.id)-\(square)"
            if let cachedThumbnail = self.entry.library.thumbnailCache.image(for: cacheName) {
                self.image = cachedThumbnail
                return
            }
            var image: UIImage?
            if isVideo {
                image = await getVideoThumbnail(url: entry.fullPath!)
            } else {
                image = await loadImage(for: entry, thumbnail: square)
            }
            guard image != nil else {return}
            self.entry.library.thumbnailCache.set(image!, for: cacheName)
            self.image = image
        }
    }
}

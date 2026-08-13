import SwiftUI
import SDWebImageSwiftUI
import AVKit
import Foundation
import SDWebImage

/// An Icon Thumbnail
struct IconThumbnail: View {
    var image: Image
    var tint: Color = .gray
    
    var body: some View {
        image
            .font(.system(size: 32))
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity
            )
            .aspectRatio(1 / 1, contentMode: .fit)
            .foregroundStyle(tint)
    }
}

/// An Icon Thumbnail based on the type of the file
struct BasicIconThumbnail: View {
    var entry: Entry
    
    var body: some View {
        IconThumbnail(image: Image(systemName: entry.type.systemImage))
    }
}

/// Displays an Image Thumbnail
struct ImageThumbnail: View {
    var image: UIImage
    var square: Bool
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: square ? .fill : .fit)
            .frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity
            )
    }
}

/// Displays a Text Thumbnail
struct TextThumbnail: View {
    var text: String
    
    var body: some View {
        Text(text)
            .font(.callout)
            .tint(.primary)
            .multilineTextAlignment(.leading)
            .frame(maxHeight: .infinity, alignment: .top)
    }
}

struct LWVideoPlayerWrapper: UIViewControllerRepresentable {
    var player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

struct LWVideoPlayer: View {
    var player: AVPlayer
    
    var body: some View {
        LWVideoPlayerWrapper(player: player)
            .scaledToFit()
    }
}

actor ThumbnailLoader {
    private var inFlight: [String: Task<UIImage?, Never>] = [:]
    static let shared = ThumbnailLoader()
    let thumbnailSize = 300
    private var access: [Library] = []
    
    func startAccess(for library: Library) {
        print("ACCESS STARTED")
        guard let bookmark = library.bookmark else { return }
        access.append(library)
        _ = bookmark.startAccessingSecurityScopedResource()
    }
    
    func stopAccess(for library: Library) {
        print("ACCESS ENDED")
        guard let bookmark = library.bookmark else { return }
        access.removeAll(where: { $0 == library})
        bookmark.stopAccessingSecurityScopedResource()
    }
    
    func thumbnail(
        for entry: Entry,
        square: Bool
    ) async -> UIImage? {
        if !access.contains(entry.library) {
            startAccess(for: entry.library)
        }
        
        let cacheName = ThumbnailLoader.getCacheName(for: entry, square: square)
        if let cached = EntryThumbnailCache.shared.image(for: cacheName) {
            return cached
        }
        
        if let existing = inFlight[cacheName] {
            return await existing.value
        }
        
        let task = Task<UIImage?, Never>(priority: .userInitiated) {
            guard let url = entry.fullPath else { return nil }
            
            var image: UIImage?
            if entry.type == .Video {
                image = await loadVideoThumbnail(for: url)
            } else {
                image = await loadImage(for: url, thumbnail: square)
            }
            guard let image = image else { return nil }
            EntryThumbnailCache.shared.set(image, for: cacheName)
            return image
        }
        inFlight[cacheName] = task
        let result = await task.value
        inFlight.removeValue(forKey: cacheName)
        
        if inFlight.isEmpty, access.contains(entry.library) {
            stopAccess(for: entry.library)
        }
        
        return result
    }
    
    func loadThumbnailImage(for url: URL) async -> UIImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: thumbnailSize
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
    
    func loadImageFull(for url: URL) async -> UIImage? {
        return UIImage(contentsOfFile: url.path)
    }
    
    func loadImage(for url: URL, thumbnail: Bool) async -> UIImage? {
        if thumbnail {
            return await loadThumbnailImage(for: url)
        } else {
            return await loadImageFull(for: url)
        }
    }
    
    func loadVideoThumbnail(for url: URL) async -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.maximumSize = CGSize(width: thumbnailSize, height: thumbnailSize)
        generator.appliesPreferredTrackTransform = true
        // Stops forcing usage of first frame
        // which can speed up generation
        generator.requestedTimeToleranceBefore = .positiveInfinity
        generator.requestedTimeToleranceAfter = .positiveInfinity
        
        do {
            let CGThumbnail = try generator.copyCGImage(at: CMTime.zero, actualTime: nil)
            return UIImage(cgImage: CGThumbnail)
        } catch {
            print(error)
        }
        return nil
    }
    
    func loadVideoPlayer(for entry: Entry) async -> AVPlayer? {
        entry.withScopedURL { url in
            let player = AVPlayer(url: url)
            player.isMuted = true
            player.play()
            
            return player
        }
    }
    
    func getTextContents(for entry: Entry) async -> String? {
        entry.withScopedURL { url in
            do {
                let fileData = try Data(contentsOf: url)
                return String(data: fileData, encoding: .utf8) ?? ""
            } catch {print(error)}
            return nil
        }
    }
    
    static func getCacheName(for entry: Entry, square: Bool) -> String {
        let url = entry.fullPath
        
        var modDate: Date = Date(timeIntervalSince1970: 0)
        var size: Int = 0
        
        do {
            let values = try url?.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            modDate = values?.contentModificationDate ?? Date(timeIntervalSince1970: 0)
            size = values?.fileSize ?? 0
        } catch {print(error)}
        
        let timestamp = Int(modDate.timeIntervalSince1970)
        
        return "\(entry.library.bookmarkKey)-\(entry.id)-\(square)-\(timestamp)-\(size)"
    }
}

extension View {
    @ViewBuilder
    func badgeGlass<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint(.black.opacity(0.5)), in: shape)
        } else {
            self.background(.regularMaterial, in: shape)
        }
    }
    

}


struct EntryThumbnailBadges: View {
    @Environment(\.colorScheme) var colorScheme
    var entry: Entry
    var showBadges: Bool {
        entry.tags?.isFavorite ?? false || entry.tags?.isArchived ?? false
    }
    
    var body: some View {
        GeometryReader { geometry in
            if showBadges && geometry.size.width > 50 {
                HStack(spacing: 2) {
                    if let tags = entry.tags {
                        if tags.all.contains(where: {$0.id == 1}) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .font(.system(size: 12))
                        }
                        if tags.all.contains(where: {$0.id == 0}) {
                            Image(systemName: "archivebox.fill")
                                .foregroundStyle(.red)
                                .font(.system(size: 12))
                        }
                    }
                }
                .padding(2)
                .badgeGlass(in: RoundedRectangle(cornerRadius: 4))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(4)
            }
        }
    }
}

struct EntryPreView: View {
    public var entry: Entry
    public var square: Bool = false
    @State var image: UIImage? = nil
    @State var text: String?
    @State var video: AVPlayer?
    @State var isUnlinked: Bool = false
    @State var blurImage: Bool = false
    
    init(entry: Entry, square: Bool = false) {
        self.entry = entry
        self.square = square
    }
    
    var body: some View {
        ZStack {
            Group {
                if isUnlinked {
                    IconThumbnail(image: Image(systemName: "link"), tint: .red)
                }
                else if let video {
                    LWVideoPlayer(player: video)
                }
                else if self.entry.type == .AnimatedImage && !square, let fullPath = entry.fullPath {
                    AnimatedImage(url: fullPath)
                        .resizable()
                        .scaledToFit()
                }
                else if let image {
                    ImageThumbnail(image: image, square: square)
                        .if(blurImage) { view in
                            view.blur(radius: 10, opaque: true)
                        }
                }
                else if let text, !text.isEmpty {
                    TextThumbnail(text: text)
                }
                else {
                    BasicIconThumbnail(entry: entry)
                }
            }
            .if(square) { view in
                view.aspectRatio(1 / 1, contentMode: .fit)
            }
            
            if square {
                EntryThumbnailBadges(entry: entry)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: square ? 0 : 8))
        .background(.background.secondary)
        .task {
            if !square {
                let cacheName = ThumbnailLoader.getCacheName(for: entry, square: true)
                if let thumb = EntryThumbnailCache.shared.image(for: cacheName) {
                    self.image = thumb
                    self.blurImage = true
                }
            }
            let exists = await Task.detached(priority: .utility) {
                await FileManager.default.fileExists(atPath: entry.fullPath?.path ?? "")
            }.value
            if !exists {
                isUnlinked = true
            } else if self.entry.type == .Video && !square {
                self.video = await ThumbnailLoader.shared.loadVideoPlayer(for: entry)
            } else if self.entry.type.supportsStillFrame {
                self.image = await ThumbnailLoader.shared.thumbnail(for: entry, square: square)
            } else if self.entry.type == .PlainText {
                self.text = await ThumbnailLoader.shared.getTextContents(for: entry)
            }
            self.blurImage = false
        }
    }
}


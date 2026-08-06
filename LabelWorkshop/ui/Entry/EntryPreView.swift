import SwiftUI
import SDWebImageSwiftUI
import AVKit
import Foundation
import SDWebImage

/// An Icon Thumbnail
struct IconThumbnail: View {
    var image: Image
    var tint: Color = .secondary
    
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
            .tint(tint)
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
            .foregroundStyle(Color(UIColor.label))
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
    private var priorityEntryIds: Set<Int> = []
    let thumbnailSize = 300
    
    func priorityUp(for entry: Entry) {
        priorityEntryIds.insert(entry.id)
    }
    
    func priorityDown(for entry: Entry) {
        priorityEntryIds.remove(entry.id)
    }
    
    func thumbnail(
        for entry: Entry,
        square: Bool
    ) async -> UIImage? {
        let cacheName = "\(entry.id)-\(square)"
        if let cached = entry.library.thumbnailCache.image(for: cacheName) {
            return cached
        }
        
        if let existing = inFlight[cacheName] {
            return await existing.value
        }
        
        // Set the priority depending on if the entry is visiable or not
        let priority: TaskPriority = priorityEntryIds.contains(entry.id) ? .high : .background
        
        let task = Task<UIImage?, Never>(priority: priority) {
            var image: UIImage?
            if entry.type == .Video {
                image = await loadVideoThumbnail(for: entry)
            } else {
                image = await loadImage(for: entry, thumbnail: square)
            }
            guard let image = image else { return nil }
            entry.library.thumbnailCache.set(image, for: cacheName)
            return image
        }
        inFlight[cacheName] = task
        let result = await task.value
        inFlight[cacheName] = nil
        return result
    }
    
    func loadThumbnailImage(for entry: Entry) async -> UIImage? {
        entry.withScopedURL { url in
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                return nil
            }

            let options: [CFString: Any] = [
                kCGImageSourceShouldCache: false,
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: thumbnailSize
            ]

            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                return nil
            }

            return UIImage(cgImage: cgImage)
        }
    }
    
    func loadImageFull(for entry: Entry) async -> UIImage? {
        entry.withScopedURL { url in
            return UIImage(contentsOfFile: url.path)
        }
    }
    
    func loadImage(for entry: Entry, thumbnail: Bool) async -> UIImage? {
        if thumbnail {
            return await loadThumbnailImage(for: entry)
        } else {
            return await loadImageFull(for: entry)
        }
    }
    
    func loadVideoThumbnail(for entry: Entry) async -> UIImage? {
        entry.withScopedURL { url in
            
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
}

struct EntryPreView: View {
    public var entry: Entry
    public var square: Bool = false
    @State var image: UIImage? = nil
    @State var text: String?
    @State var video: AVPlayer?
    @State var isUnlinked: Bool = false
    
    init(entry: Entry, square: Bool = false) {
        self.entry = entry
        self.square = square
    }
    
    var body: some View {
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
        .clipShape(RoundedRectangle(cornerRadius: square ? 0 : 8))
        .background(Color(UIColor.secondarySystemBackground))
        .task {
            let exists = await Task.detached(priority: .utility) {
                FileManager.default.fileExists(atPath: entry.fullPath?.path ?? "")
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
        }
        .onAppear {
            Task {
                await ThumbnailLoader.shared.priorityUp(for: entry)
            }
        }
        .onDisappear {
            Task {
                await ThumbnailLoader.shared.priorityDown(for: entry)
            }
        }
    }
}

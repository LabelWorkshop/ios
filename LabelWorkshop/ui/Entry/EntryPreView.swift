import SwiftUI
import SDWebImageSwiftUI
import AVKit
import Foundation
import SDWebImage

extension CGSize {
    /// Get the size of the largest side.
    var largest: CGFloat {
        if width > height {
            return width
        } else {
            return height
        }
    }
}

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

/// An Icon Thumbnail
struct BasicIconThumbnail: View {
    var entry: Entry
    
    var body: some View {
        switch self.entry.type {
        case .Audio:
            IconThumbnail(image: Image(systemName: "waveform"))
        case .Image:
            IconThumbnail(image: Image(systemName: "photo"))
        case .Video:
            IconThumbnail(image: Image(systemName: "movieclapper"))
        case .Archive:
            IconThumbnail(image: Image(systemName: "zipper.page"))
        case .PlainText:
            IconThumbnail(image: Image(systemName: "text.document"))
        case .AnimatedImage:
            IconThumbnail(image: Image(systemName: "square.3.layers.3d.down.forward"))
        case .Unknown:
            IconThumbnail(image: Image(systemName: "exclamationmark.triangle.fill"))
        }
    }
}

/// Displays an Image Thumbnail
struct ImageThumbnail: View {
    var image: UIImage
    var square: Bool
    
    var body: some View {
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
            
        } else {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        }
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
        let priority: TaskPriority = priorityEntryIds.contains(entry.id) ? .high : .userInitiated
        
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
    
    func thumbnailifyUIImage(_ uiImage: UIImage) async -> UIImage? {
        return await Task(priority: .userInitiated) {
            uiImage.preparingThumbnail(of: CGSize(width: thumbnailSize, height: thumbnailSize))
        }.value
    }
    
    func loadImage(for entry: Entry, thumbnail: Bool = false) async -> UIImage? {
        guard let path = entry.fullPath else { return nil }
        guard let bookmark = entry.library.bookmark else { return nil }
        guard bookmark.startAccessingSecurityScopedResource() else { return nil }
        defer { bookmark.stopAccessingSecurityScopedResource() }
        guard let uiImage = UIImage(contentsOfFile: path.path) else {return nil}
        if !thumbnail || Int(uiImage.size.largest) <= thumbnailSize {
            return uiImage
        }
        return await self.thumbnailifyUIImage(uiImage)
    }
    
    func loadVideoThumbnail(for entry: Entry) async -> UIImage? {
        guard let url = entry.fullPath else { return nil }
        guard let bookmark = entry.library.bookmark else { return nil }
        guard bookmark.startAccessingSecurityScopedResource() else { return nil }
        defer { bookmark.stopAccessingSecurityScopedResource() }
        
        let asset = AVURLAsset(url: url)
        let assetIG = AVAssetImageGenerator(asset: asset)
        
        let timestamp = CMTime(seconds: 0, preferredTimescale: 60)
        do {
            let CGThumbnail = try assetIG.copyCGImage(at: timestamp, actualTime: nil)
            let fullUIThumbnail = UIImage(cgImage: CGThumbnail)
            return await self.thumbnailifyUIImage(fullUIThumbnail)
        } catch {
            print(error)
        }
        return nil
    }
    
    func loadVideoPlayer(for entry: Entry) async -> AVPlayer? {
        guard let url = entry.fullPath else { return nil }
        guard let bookmark = entry.library.bookmark else { return nil }
        guard bookmark.startAccessingSecurityScopedResource() else { return nil }
        defer { bookmark.stopAccessingSecurityScopedResource() }
        let player = AVPlayer(url: url)
        player.isMuted = true
        player.play()
        
        return player
    }
    
    func getTextContents(for entry: Entry) async -> String? {
        guard let bookmark = entry.library.bookmark else {return nil}
        guard bookmark.startAccessingSecurityScopedResource() == true else {return nil}
        defer { bookmark.stopAccessingSecurityScopedResource() }
        guard let file = entry.fullPath else {return nil}
        do {
            let fileData = try Data(contentsOf: file)
            return String(data: fileData, encoding: .utf8) ?? ""
        } catch {print(error)}
        return nil
    }
}

enum ExtensionTypes {
    case Image
    case Video
    case AnimatedImage
    case Audio
    case Archive
    case PlainText
    case Unknown
}

struct EntryPreView: View {
    public var entry: Entry
    public var square: Bool = false
    @State var image: UIImage? = nil
    @State var text: String?
    @State var video: AVPlayer?
    
    init(entry: Entry, square: Bool = false) {
        self.entry = entry
        self.square = square
    }
    
    var body: some View {
        Group {
            if !FileManager.default.fileExists(atPath: entry.fullPath?.path ?? "") {
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
            guard self.entry.type == .Image || self.entry.type == .Video || self.entry.type == .AnimatedImage else {return}
            self.image = await ThumbnailLoader.shared.thumbnail(for: entry, square: square)
        }
        .task {
            guard self.entry.type == .Video && !square else {return}
            self.video = await ThumbnailLoader.shared.loadVideoPlayer(for: entry)
        }
        .task {
            guard self.entry.type == .PlainText else {return}
            self.text = await ThumbnailLoader.shared.getTextContents(for: entry)
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

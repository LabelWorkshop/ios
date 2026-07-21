import SwiftUI
import SDWebImageSwiftUI
import AVKit
import Foundation
import SDWebImage

extension CGSize {
    var largest: CGFloat {
        if width > height {
            return width
        } else {
            return height
        }
    }
}

actor ThumbnailLoader {
    private var inFlight: [String: Task<UIImage?, Never>] = [:]
    static let shared = ThumbnailLoader()
    
    func thumbnail(
        for entry: Entry,
        square: Bool,
        type: ExtensionTypes
    ) async -> UIImage? {
        let cacheName = "\(entry.id)-\(square)"
        if let cached = entry.library.thumbnailCache.image(for: cacheName) {
            return cached
        }
        
        if let existing = inFlight[cacheName] {
            return await existing.value
            
        }
        
        let task = Task<UIImage?, Never>(priority: .userInitiated) {
            var image: UIImage?
            if type == .Video {
                image = await getVideoThumbnail(url: entry.fullPath!)
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
}

func loadImage(for entry: Entry, thumbnail: Bool = false) async -> UIImage? {
    guard let path = entry.fullPath else { return nil }
    guard let bookmark = entry.library.bookmark else { return nil }
    guard bookmark.startAccessingSecurityScopedResource() else { return nil }
    defer { bookmark.stopAccessingSecurityScopedResource() }
    if let data = try? Data(contentsOf: path) {
        guard let uiImage = UIImage(data: data) else {return nil}
        if thumbnail {
            if uiImage.size.largest > 300 {
                return await Task(priority: .userInitiated) {
                    uiImage.preparingThumbnail(of: CGSize(width: 300, height: 300))
                }.value
            }
            return uiImage
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

func getTextContents(for entry: Entry) -> String? {
    guard let bookmark = entry.library.bookmark else {return nil}
    guard bookmark.startAccessingSecurityScopedResource() == true else {return nil}
    defer { bookmark.stopAccessingSecurityScopedResource() }
    if let file = entry.fullPath {
        do {
            let fileData = try Data(contentsOf: file)
            return String(data: fileData, encoding: .utf8) ?? ""
        } catch {print(error)}
    }
    return nil
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

enum ExtensionTypes {
    case Image
    case Video
    case AnimatedImage
    case Audio
    case Archive
    case PlainText
    case Unknown
}

func getExtensionType(for ext: String) -> ExtensionTypes {
    let type = UTType(filenameExtension: ext)
    if type?.conforms(to: .gif) ?? false {
        return .AnimatedImage
    }
    if type?.conforms(to: .movie) ?? false {
        return .Video
    }
    if type?.conforms(to: .image) ?? false || ext == "pxd" {
        return .Image
    }
    if type?.conforms(to: .audio) ?? false {
        return .Audio
    }
    if type?.conforms(to: .archive) ?? false {
        return .Archive
    }
    if ["txt",
        "json",
        "md",
        "plist",
        "strings",
        "yml",
        "yaml",
        "toml",
        "ini",
        "gitignore",
        "gitattributes",
        "log"
    ].contains(ext) {
        return .PlainText
    }
    return .Unknown
}

struct EntryPreView: View {
    public var entry: Entry
    public var square: Bool = false
    var ext: String
    var type: ExtensionTypes
    @State var image: UIImage? = nil
    
    init(entry: Entry, square: Bool = false) {
        self.entry = entry
        self.square = square
        self.ext = entry.path.split(separator: ".").last?.lowercased() ?? ""
        self.type = getExtensionType(for: ext)
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
            else if self.type == .Video && !square {
                VideoPlayerContainer(entry: entry)
                    .scaledToFill()
            }
            else if self.type == .AnimatedImage && !square {
                AnimatedImage(url: entry.fullPath!)
                    .resizable()
                    .scaledToFit()
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
                VStack {
                    switch self.type {
                    case .Audio:
                        Image(systemName: "waveform").font(.system(size: 32))
                    case .Image:
                        Image(systemName: "photo").font(.system(size: 32))
                    case .Video:
                        Image(systemName: "movieclapper").font(.system(size: 32))
                    case .Archive:
                        Image(systemName: "zipper.page").font(.system(size: 32))
                    case .PlainText:
                        let content = getTextContents(for: entry) ?? ""
                        if !content.isEmpty {
                            Text(content)
                                .font(.callout)
                                .foregroundStyle(Color(UIColor.label))
                                .multilineTextAlignment(.leading)
                                .frame(maxHeight: .infinity, alignment: .top)
                        } else {
                            Image(systemName: "text.document").font(.system(size: 32))
                        }
                    case .AnimatedImage:
                        Image(systemName: "square.3.layers.3d.down.forward").font(.system(size: 32))
                    case .Unknown:
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 32))
                        Text("No preview available")
                            .foregroundStyle(Color(UIColor.label))
                    }
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
        .cornerRadius(square ? 0 : 8)
        .task {
            guard self.type == .Image || self.type == .Video || self.type == .AnimatedImage else {return}
            self.image = await ThumbnailLoader.shared.thumbnail(for: entry, square: square, type: type)
        }
    }
}

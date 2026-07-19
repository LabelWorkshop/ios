import SwiftUI
import AVKit
import Foundation

extension CGSize {
    var largest: CGFloat {
        if width > height {
            return width
        } else {
            return height
        }
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
                let thumbnailImage = uiImage.preparingThumbnail(of: CGSize(width: 300, height: 300))
                return thumbnailImage
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

struct EntryPreView: View {
    public var entry: Entry
    public var square: Bool = false
    var ext: String?
    var isVideo: Bool
    var isImage: Bool
    var isAudio: Bool
    var isZIP: Bool
    var isText: Bool
    @State var image: UIImage? = nil
    
    init(entry: Entry, square: Bool = false) {
        self.entry = entry
        self.square = square
        self.ext = entry.path.split(separator: ".").last?.lowercased()
        let type = UTType(filenameExtension: self.entry.fullPath?.pathExtension ?? "")
        self.isVideo = type?.conforms(to: .movie) ?? false
        self.isImage = type?.conforms(to: .image) ?? false || self.ext == "pxd"
        self.isAudio = type?.conforms(to: .audio) ?? false
        self.isZIP = type?.conforms(to: .archive) ?? false
        self.isText = ["txt", "json", "md", "plist", "strings", "yml", "yaml", "toml", "ini", "gitignore", "gitattributes", "log"].contains(self.ext)
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
                VStack {
                    if isAudio {
                        Image(systemName: "waveform").font(.system(size: 32))
                    } else if isImage {
                        Image(systemName: "photo").font(.system(size: 32))
                    } else if isVideo {
                        Image(systemName: "movieclapper").font(.system(size: 32))
                    } else if isVideo {
                        Image(systemName: "zipper.page").font(.system(size: 32))
                    } else if isText {
                        if let content = getTextContents(for: entry) {
                            Text(content)
                                .font(.callout)
                                .foregroundStyle(Color(UIColor.label))
                                .multilineTextAlignment(.leading)
                                .frame(maxHeight: .infinity, alignment: .top)
                        } else {
                            Image(systemName: "text.document").font(.system(size: 32))
                        }
                    } else {
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

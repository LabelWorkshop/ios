import SwiftUI

final class EntryThumbnailCache {
    static let shared = EntryThumbnailCache()
    private let cache = NSCache<NSString, UIImage>()
    func image(for key: String) -> UIImage? { cache.object(forKey: key as NSString) }
    func set(_ image: UIImage, for key: String) { cache.setObject(image, forKey: key as NSString) }
}

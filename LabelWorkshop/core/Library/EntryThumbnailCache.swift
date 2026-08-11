import SwiftUI

enum ThumbnailStorageError: Error {
    case jpegFailed
    case cacheUnavilaible
}

final class EntryThumbnailCache {
    private static var cachesDirectory: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    }
    
    static let shared = EntryThumbnailCache()
    private let cache = NSCache<NSString, UIImage>()
    
    func image(for key: String) -> UIImage? {
        let memoryCacheItem = cache.object(forKey: key as NSString)
        
        if memoryCacheItem != nil {
            return memoryCacheItem
        }
        
        do {
            guard let caches = EntryThumbnailCache.cachesDirectory else {
                throw ThumbnailStorageError.cacheUnavilaible
            }
            let url = caches.appendingPathComponent(key)
            guard FileManager.default.fileExists(atPath: url.path) else {
                return nil
            }
            
            guard let diskImage = UIImage(data: try Data(contentsOf: url)) else {
                return nil
            }
            cache.setObject(diskImage, forKey: key as NSString)
            return diskImage
        } catch {
            print(error)
        }
        
        return nil
    }
    
    func set(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
        
        do {
            guard let data = image.jpegData(compressionQuality: 0.7) else {
                throw ThumbnailStorageError.jpegFailed
            }
            
            guard let caches = EntryThumbnailCache.cachesDirectory else {
                throw ThumbnailStorageError.cacheUnavilaible
            }
            let url = caches.appendingPathComponent(key)
            
            try data.write(to: url, options: .atomic)
        } catch {
            print("Thumbnail not saved to disk.")
            print(error)
        }
    }
    
    func clear() throws {
        clearMemory()
        try clearDisk()
    }
    
    func clearDisk() throws {
        guard let caches = EntryThumbnailCache.cachesDirectory else {
            throw ThumbnailStorageError.cacheUnavilaible
        }
        
        let fileURLs = try FileManager.default.contentsOfDirectory(at: caches, includingPropertiesForKeys: nil, options: [])
        
        for fileURL in fileURLs {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
    
    func clearMemory() {
        self.cache.removeAllObjects()
    }
}

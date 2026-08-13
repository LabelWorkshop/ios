import Foundation

class BookmarkManager {
    public var bookmarkKey: String
    var bookmarkURL: URL?
    
    var TSFolder: URL? {
        bookmarkURL?.appendingPathComponent(".TagStudio/")
    }
    
    var TSIgnoreFile: URL? {
        TSFolder?.appendingPathComponent(".ts_ignore")
    }
    
    var TSDatabaseFile: URL? {
        TSFolder?.appendingPathComponent("ts_library.sqlite")
    }
    
    var TSLegacyDatabaseFile: URL? {
        TSFolder?.appendingPathComponent("ts_library.json")
    }
    
    init(bookmarkKey: String) {
        self.bookmarkKey = bookmarkKey
        self.bookmarkURL = loadBookmark(key: bookmarkKey)
    }
    
    func loadBookmark(key: String) -> URL? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }

        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {return nil}
            return url
        } catch {
            print(error)
            return nil
        }
    }
    
    func startAccessingSecurityScopedResource() -> Bool {
        return bookmarkURL?.startAccessingSecurityScopedResource() ?? false
    }
    
    func stopAccessingSecurityScopedResource() {
        bookmarkURL?.stopAccessingSecurityScopedResource()
    }
    
    func withAccess<T>(
        _ body: () throws -> T?
    ) rethrows -> T? {
        guard startAccessingSecurityScopedResource()
        else {
            return nil
        }

        defer {
            stopAccessingSecurityScopedResource()
        }

        return try body()
    }
}

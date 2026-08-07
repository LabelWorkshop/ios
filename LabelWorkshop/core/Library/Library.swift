import Foundation
import UIKit
import SQLite
import PathKit

enum LibraryError: Error {
    case databaseInvalid
    case databaseUnmigrateable
    case fieldTemplateInvalid
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

extension Connection {
    public var legacyDatabaseVersion: Int {
        get { return Int((try? scalar("PRAGMA schema_version") as? Int64) ?? 0) }
        set { _ = try? run("PRAGMA schema_version = \(newValue)") }
    }
    
    public var databaseVersion: Int {
        get {
            if let row = try? self.pluck(VersionTable.table.filter(VersionTable.key == "CURRENT")) {
                return row[VersionTable.value]
            }
            return 0
        }
        set { _ = try? self.run(VersionTable.table.filter(VersionTable.key == "CURRENT")
            .update(VersionTable.value <- Int(newValue)))
        }
    }
}

@Observable
class Library: Hashable, Identifiable, Equatable {
    static func == (lhs: Library, rhs: Library) -> Bool {
        return lhs.bookmarkKey == rhs.bookmarkKey
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(bookmarkKey)
    }
    
    var bookmarkKey: String
    var bookmark: URL?
    var db: Connection?
    var tagColors: TagColorManager!
    var fieldTemplates: FieldTemplateManager?
    var ignoreList: String = "\n.TagStudio\n.DS_Store"
    var matcher: TSIgnoreMatcher?
    var isNew: Bool
    var entries: EntryManager!
    var migrator: LibraryMigrator!
    
    var tags: LibraryTagManager!
    
    var thumbnailCache: EntryThumbnailCache = EntryThumbnailCache()
    
    init(bookmarkKey: String) {
        self.bookmarkKey = bookmarkKey
        self.bookmark = loadBookmark(key: bookmarkKey)
        self.isNew = false
        do {
            if let bookmark = bookmark {
                // Create TagStudio folder if not already created
                try FileManager.default.createDirectory(
                    at: bookmark.appendingPathComponent(".TagStudio"),
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                self.isNew = !FileManager.default.fileExists(atPath: bookmark.appendingPathComponent(".TagStudio/ts_library.sqlite").path)
                
                // Inititalize Database
                let dbFile = bookmark.appendingPathComponent(".TagStudio/ts_library.sqlite").absoluteString
                self.db = try Connection(dbFile)
            }
            
            // Get Tags & Tag Colors
            self.tagColors = TagColorManager(library: self)
            self.tags = LibraryTagManager(library: self)
            
            // Get Field Types
            self.fieldTemplates = try FieldTemplateManager(library: self)
            
            // Get Entries
            self.entries = EntryManager(library: self)
            
            self.migrator = LibraryMigrator(library: self)
            
            // Check for migrations asynchronously
            Task { [weak self] in
                do {
                    try await self?.migrator.migrate()
                    self?.refresh()
                } catch {
                    print(error)
                }
            }
        } catch {print(error)}
    }
    
    func refresh() {
        do {
            // Get .ts_ignore file
            let ignoreFile = self.bookmark?.appendingPathComponent(".TagStudio/.ts_ignore")
            guard bookmark?.startAccessingSecurityScopedResource() == true else { throw LibraryError.databaseInvalid }
            defer { bookmark?.stopAccessingSecurityScopedResource() }
            if let ignoreFile = ignoreFile {
                let ignoreData = try Data(contentsOf: ignoreFile)
                ignoreList = String(data: ignoreData, encoding: .utf8) ?? ""
            }
            ignoreList.append("\n.TagStudio\n.DS_Store")
            
            if let bookmark = self.bookmark {
                self.matcher = TSIgnoreMatcher(contents: ignoreList, baseURL: bookmark)
            }
            
            // Find New Entries
            Task(priority: .background) {
                do {
                    try self.addNewEntries()
                } catch {print(error)}
            }
        } catch {print(error)}
    }
    
    func findNewFiles() throws -> [Path] {
        guard bookmark?.startAccessingSecurityScopedResource() == true else { throw LibraryError.databaseInvalid }
        defer { bookmark?.stopAccessingSecurityScopedResource() }
        
        let libPathString = bookmark?.path
        guard libPathString != nil else {return []}
        let libPath = Path(libPathString!)
        
        var allChildren: [Path] = try libPath.recursiveChildren()
        var newFiles: [Path] = []
        let entries: [Entry] = self.entries.all
        
        // Remove any paths that are already present as entries
        allChildren.removeAll { child in
            entries.contains { entry in
                return entry.fullPath == child.url
            }
        }
        
        for child in allChildren {
            if !(self.matcher?.isIgnored(url: child.url) ?? true) && !child.isDirectory {
                newFiles.append(child)
            }
        }
        
        return newFiles
    }
    
    func getName() -> (String) {
        guard bookmark?.startAccessingSecurityScopedResource() == true else { return "Unknown" }
        defer { bookmark?.stopAccessingSecurityScopedResource() }
        let name = bookmark?.absoluteString.removingPercentEncoding?.split(separator: "/").last ?? "Unknown"
        return String(name)
    }
    
    func addNewEntries() throws {
        let newFiles = try findNewFiles()
        for file in newFiles {
            try self.entries.add(path: file.url)
        }
    }
    
    func withDatabase<T>(
        _ body: (Connection) throws -> T?
    ) rethrows -> T? {
        guard let db = self.db else {
            return nil
        }

        return try body(db)
    }
}


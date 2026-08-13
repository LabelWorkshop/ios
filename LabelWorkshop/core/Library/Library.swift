import Foundation
import SQLite
import PathKit

enum LibraryError: Error {
    case databaseInvalid
    case databaseUnmigrateable
    case fieldTemplateInvalid
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
        return lhs.bookmark.bookmarkKey == rhs.bookmark.bookmarkKey
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(bookmark.bookmarkKey)
    }
    
    var bookmark: BookmarkManager
    var db: Connection?
    var tagColors: TagColorManager!
    var fieldTemplates: FieldTemplateManager?
    var ignoreList: String = "\n.TagStudio\n.DS_Store"
    var matcher: TSIgnoreMatcher?
    var isNew: Bool
    var entries: EntryManager!
    var migrator: LibraryMigrator?
    
    var tags: LibraryTagManager!
    
    var legacyLibraryAvailable: Bool {
        if let legacyPath = self.bookmark.TSLegacyDatabaseFile?.path {
            return FileManager.default.fileExists(atPath: legacyPath)
        }
        return false
    }
    
    init(bookmarkKey: String) {
        self.bookmark = BookmarkManager(bookmarkKey: bookmarkKey)
        self.isNew = false
        
        self.migrator = LibraryMigrator(library: self)
        
        do {
            if let TSFolder = bookmark.TSFolder,
               let TSDatabaseFile = bookmark.TSDatabaseFile {
                // Create TagStudio folder if not already created
                try FileManager.default.createDirectory(
                    at: TSFolder,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                self.isNew = !FileManager.default.fileExists(atPath: TSDatabaseFile.path)
                
                // Inititalize Database
                self.db = try Connection(TSDatabaseFile.absoluteString)
            }
            
            // Get Tags & Tag Colors
            self.tagColors = TagColorManager(library: self)
            self.tags = LibraryTagManager(library: self)
            
            // Get Field Types
            self.fieldTemplates = try FieldTemplateManager(library: self)
            
            // Get Entries
            self.entries = EntryManager(library: self)
            
            // Check for migrations asynchronously
            Task { [weak self] in
                do {
                    try await self?.migrator?.migrate()
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
            guard let ignoreFile = bookmark.TSIgnoreFile else { return }
            try bookmark.withAccess {
                let ignoreData = try Data(contentsOf: ignoreFile)
                ignoreList = String(data: ignoreData, encoding: .utf8) ?? ""
                ignoreList.append("\n.TagStudio\n.DS_Store")
                
                if let bookmarkURL = self.bookmark.bookmarkURL {
                    self.matcher = TSIgnoreMatcher(contents: ignoreList, baseURL: bookmarkURL)
                }
                
                // Find New Entries
                Task(priority: .background) {
                    do {
                        try self.addNewEntries()
                    } catch {print(error)}
                }
            }
        } catch {print(error)}
    }
    
    func findNewFiles() throws -> [Path] {
        var newFiles: [Path] = []
        
        guard let libPathString = bookmark.bookmarkURL?.path else {
            throw LibraryError.databaseInvalid
        }
        
        try bookmark.withAccess {
            let libPath = Path(libPathString)
            
            var allChildren: [Path] = try libPath.recursiveChildren()
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
        }
        
        return newFiles
    }
    
    func getName() -> (String) {
        var name = "Unknown"
        bookmark.withAccess {
            name = String(bookmark.bookmarkURL?.absoluteString.removingPercentEncoding?.split(separator: "/").last ?? "Unknown")
        }
        
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


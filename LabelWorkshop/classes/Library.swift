import Foundation
import SQLite

enum LibraryError: Error {
    case databaseInvalid
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
    } catch {return nil}
}

class Library: Hashable, Identifiable {
    static func == (lhs: Library, rhs: Library) -> Bool {
        return lhs.bookmarkKey == rhs.bookmarkKey
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(bookmarkKey)
    }
    
    var bookmarkKey: String
    
    var _bookmark: URL?
    var bookmark: URL? {
        get {
            if self._bookmark == nil {
                self._bookmark = loadBookmark(key: self.bookmarkKey)
            }
            return self._bookmark
        }
    }
    var _db: Connection?
    var db: Connection? {
        get {
            if self._db == nil {
                do {
                    let dbFile = self.bookmark?.appendingPathComponent(".TagStudio/ts_library.sqlite").absoluteString ?? ""
                    self._db = try Connection(dbFile)
                } catch {}
            }
            return self._db
        }
    }
    
    static var entriesTable: Table = Table("entries")
    static var pathColumn = Expression<String>("path")
    static var entryIdColumn = Expression<Int>("id")
    
    var _tagColors: TagColorManager?
    var tagColors: TagColorManager? {
        get {
            if self._tagColors == nil {
                self._tagColors = TagColorManager(library: self)
            }
            return self._tagColors
        }
    }
    
    static var sequenceTable = Table("sqlite_sequence")
    static var nameColumn = Expression<String?>("name")
    static var sequenceColumn = Expression<Int?>("seq")
    
    init(bookmarkKey: String) {
        self.bookmarkKey = bookmarkKey
    }
    
    func getName() -> (String) {
        guard bookmark?.startAccessingSecurityScopedResource() == true else { return "Unknown" }
        defer { bookmark?.stopAccessingSecurityScopedResource() }
        let name = bookmark?.absoluteString.removingPercentEncoding?.split(separator: "/").last ?? "Unknown"
        return String(name)
    }
    
    func getEntries() throws -> [Entry] {
        if self.db == nil { throw LibraryError.databaseInvalid }
        var entries: [Entry] = []
        do {
            for rawEntry in try self.db!.prepare(Library.entriesTable) {
                let path: String = rawEntry[Library.pathColumn]
                let id: Int = rawEntry[Library.entryIdColumn]
                entries.append(Entry(library: self, path: path, id: id))
            }
        } catch {
            throw LibraryError.databaseInvalid
        }
        return entries
    }
    
    func safeGetEntries() -> [Entry] {
        do {
            return try self.getEntries()
        } catch {
            return []
        }
    }
    
    func newTag(_ name: String) -> Tag? {
        let sequenceQuery = Library.sequenceTable.filter(Library.nameColumn == "tags")
        do {
            if let raw = try self.db?.pluck(sequenceQuery) {
                let sequence = raw[Library.sequenceColumn]
                if let sequence = sequence {
                    let query = Tag.tagsTable.insert(
                        Tag.nameColumn <- name,
                        Tag.isCategoryColumn <- false,
                    )
                    try self.db?.run(query)
                    return Tag (
                        library: self,
                        name: name,
                        id: sequence,
                        colors: TagColor.none,
                        shorthand: nil,
                        isCategory: false,
                        disambiguationId: nil
                    )
                }
            }
        } catch {}
        return nil
    }
}

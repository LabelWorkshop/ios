import Foundation
import SQLite

class Entry {
    var path: String
    var id: Int
    var fullPath: URL?
    let library: Library
    
    static var tagEntriesTable: Table = Table("tag_entries")
    static var idColumn = Expression<Int>("tag_id")
    static var entryColumn = Expression<Int>("entry_id")
    
    init (library: Library, path: String, id: Int) {
        self.path = path
        self.library = library
        self.id = id
        if library.bookmark != nil { self.fullPath = library.bookmark?.appendingPathComponent(path) }
    }
    
    func getTags() -> [Tag] {
        let query = Entry.tagEntriesTable.select(*).filter(Entry.entryColumn == self.id)
        var tags: [Tag] = []
        do {
            for rawTag in try self.library.db!.prepare(query) {
                let tag = Tag.fetch(library: self.library, id: rawTag[Entry.idColumn])
                if let tag = tag {
                    tags.append(tag)
                }
            }
        } catch {}
        return tags
    }
}

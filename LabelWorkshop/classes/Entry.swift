import Foundation
import SQLite

class Entry {
    var path: String
    var id: Int
    var fullPath: URL?
    let library: Library
    
    var tagEntriesTable: Table = Table("tag_entries")
    var idColumn = Expression<Int>("tag_id")
    var entryColumn = Expression<Int>("entry_id")
    
    init (library: Library, path: String, id: Int) {
        self.path = path
        self.library = library
        self.id = id
        if library.bookmark != nil { self.fullPath = library.bookmark?.appendingPathComponent(path) }
    }
    
    func getTags() -> [Tag] {
        let query = self.tagEntriesTable.select(*).filter(entryColumn == self.id)
        var tags: [Tag] = []
        do {
            for rawTag in try self.library.db!.prepare(query) {
                let tag = Tag.fetch(library: self.library, id: rawTag[idColumn])
                if let tag = tag {
                    tags.append(tag)
                }
            }
        } catch {}
        return tags
    }
    
    func delete() {
        let queries = [
            Table("boolean_fields")
                .filter(Expression<Int>("entry_id") == self.id)
                .delete(),
            Table("datetime_fields")
                .filter(Expression<Int>("entry_id") == self.id)
                .delete(),
            Table("text_fields")
                .filter(Expression<Int>("entry_id") == self.id)
                .delete(),
            Table("tag_entries")
                .filter(Expression<Int>("entry_id") == self.id)
                .delete(),
            Library.entriesTable
                .filter(Library.entryIdColumn == self.id)
                .delete()
        ]
        do {
            for query in queries {
                try self.library.db!.run(query)
            }
        } catch {}
    }
}

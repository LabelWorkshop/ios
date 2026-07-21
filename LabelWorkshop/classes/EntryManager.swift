import SQLite
import Foundation

enum EntryManagerError: Error {
    case insertionFailed
}

@Observable
class EntryManager {
    let library: Library
    private var entries: [Entry] = []
    var all: [Entry] { entries }
    
    init(library: Library) {
        self.library = library
        self.refresh()
    }
    
    func refresh() {
        var updatedEntries: [Entry] = []
        guard let db = self.library.db else { return }
        do {
            for rawEntry in try db.prepare(EntriesTable.table) {
                let path: String = rawEntry[EntriesTable.path]
                let id: Int = rawEntry[EntriesTable.id]
                updatedEntries.append(Entry(library: self.library, path: path, id: id))
            }
        } catch {print(error)}
        self.entries = updatedEntries
    }
    
    func add(path: URL) throws {
        // Path
        guard let bookmark = self.library.bookmark else { throw LibraryError.databaseInvalid }
        guard let filepath = path.absoluteString.replacingOccurrences(of: bookmark.absoluteString, with: "").removingPercentEncoding else {
            throw LibraryError.databaseInvalid
        }
        // Filename
        let filename = path.lastPathComponent
        
        let insertEntry = EntriesTable.table.insert(
            EntriesTable.path <- filepath,
            EntriesTable.filename <- filename,
            EntriesTable.dateCreated <- Date(),
            EntriesTable.suffix <- path.pathExtension,
            EntriesTable.folderId <- 0
        )
        
        guard let id = try self.library.db?.run(insertEntry) else {throw EntryManagerError.insertionFailed}
        
        self.entries.append(Entry(library: self.library, path: filepath, id: Int(id)))
    }
    
    func delete(_ entry: Entry) {
        let queries = [
            DateFieldsTable.table
                .filter(EntriesTable.id == entry.id)
                .delete(),
            TextFieldsTable.table
                .filter(EntriesTable.id == entry.id)
                .delete(),
            TagEntriesTable.table
                .filter(EntriesTable.id == entry.id)
                .delete(),
            EntriesTable.table
                .filter(EntriesTable.id == entry.id)
                .delete()
        ]
        do {
            try self.library.db?.transaction {
                for query in queries {
                    try self.library.db!.run(query)
                }
            }
            self.entries.removeAll(where: { $0.id == entry.id })
        } catch {print(error)}
    }
}

import SQLite
import Foundation

class EntryManager {
    let library: Library
    private var entries: [Entry] = []
    var all: [Entry] { return self.entries }
    
    init(library: Library) {
        self.library = library
        self.update()
    }
    
    func update() {
        var updatedEntries: [Entry] = []
        do {
            for rawEntry in try library.db!.prepare(EntriesTable.table) {
                let path: String = rawEntry[EntriesTable.path]
                let id: Int = rawEntry[EntriesTable.id]
                updatedEntries.append(Entry(library: self.library, path: path, id: id))
            }
        } catch {print(error)}
        self.entries = updatedEntries
    }
    
    func add(path: URL) throws {
        // Path
        guard let filepath = path.absoluteString.replacingOccurrences(of: self.library.bookmark!.absoluteString, with: "").removingPercentEncoding else {
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
        
        try self.library.db?.run(insertEntry)
        self.update()
    }
}

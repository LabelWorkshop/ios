import SQLite
import Foundation

enum EntryManagerError: Error {
    case insertionFailed
}

enum SortType {
    case id
    case filename
    case path
}

@Observable
class EntryManager {
    let library: Library
    private var entries: [Entry] = []
    var all: [Entry] { entries }
    var count: Int {entries.count}
    
    init(library: Library) {
        self.library = library
        do {
            try self.refresh()
        } catch {
            print("EntryManager couldn't be initialized")
        }
    }
    
    func refresh() throws {
        var updatedEntries: [Entry] = []
        for rawEntry in try self.library.db.prepare(EntriesTable.table) {
            let path: String = rawEntry[EntriesTable.path]
            let id: Int = rawEntry[EntriesTable.id]
            updatedEntries.append(Entry(library: self.library, path: path, id: id))
        }
        self.entries = updatedEntries
    }
    
    func add(path: URL) throws {
        // Path
        guard let filepath = path.absoluteString.replacingOccurrences(of: self.library.bookmark.absoluteString, with: "").removingPercentEncoding else {
            throw LibraryError.databaseInvalid
        }
        // Filename
        let filename = path.lastPathComponent
        
        let insertEntry = EntriesTable.table.insert(
            EntriesTable.path <- filepath,
            EntriesTable.filename <- filename,
            EntriesTable.dateCreated <- Date(),
            EntriesTable.suffix <- path.pathExtension
        )
        
        let id = try self.library.db.run(insertEntry)
        
        self.entries.append(Entry(library: self.library, path: filepath, id: Int(id)))
    }
    
    func delete(_ entry: Entry) throws {
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
        
        try self.library.db.transaction {
            for query in queries {
                try self.library.db.run(query)
            }
            self.entries.removeAll(where: { $0.id == entry.id })
        }
    }
    
    func getIndex(of entry: Entry) -> Int? {
        entries.firstIndex(where: {$0.id == entry.id})
    }
    
    func getSorted(_ sort: SortType, ascending: Bool) -> [Entry] {
        var sorted: [Entry] = []
        switch sort {
        case .path:
            sorted = self.entries.sorted {
                $0.path.localizedCaseInsensitiveCompare($1.path) == .orderedAscending
            }
        case .id:
            sorted = self.entries.sorted {
                $0.id < $1.id
            }
        case .filename:
            sorted = self.entries.sorted {
                let filename0 = $0.fullPath?.lastPathComponent ?? ""
                let filename1 = $1.fullPath?.lastPathComponent ?? ""
                return filename0.localizedCaseInsensitiveCompare(filename1) == .orderedAscending
            }
        }
        
        if !ascending {
            sorted.reverse()
        }
        
        return sorted
    }
}

import SQLite

class EntryTagManager {
    let entry: Entry
    private var tags: [Tag] = []
    var all: [Tag] {
        get {
            return self.tags
        }
    }
    
    init(_ entry: Entry) {
        self.entry = entry
        self.refresh()
    }
    
    /// Refresh the list of tags
    func refresh() {
        let query = Entry.tagEntriesTable.select(*).filter(Entry.entryColumn == self.entry.id)
        var tags: [Tag] = []
        do {
            for rawTag in try self.entry.library.db!.prepare(query) {
                let tag = self.entry.library.tags.getById(id: rawTag[Entry.idColumn])
                if let tag = tag {
                    tags.append(tag)
                }
            }
        } catch {print(error)}
        self.tags = tags
    }
    
    func isEmpty() -> Bool {
        return self.tags.isEmpty
    }
    
    func containsAll(_ tags: [Tag]) -> Bool {
        for tag in tags {
            if !self.tags.contains(where: { $0.id == tag.id }) {
                return false
            }
        }
        return true
    }
    
    func add(_ tag: Tag) {
        // Check if tag already exists on entry
        if self.containsAll([tag]) {
            return
        }
        
        let query = Entry.tagEntriesTable.insert(Entry.idColumn <- tag.id, Entry.entryColumn <- self.entry.id)
        do {
            try self.entry.library.db!.run(query)
        } catch {print(error)}
        self.refresh()
    }
    
    func remove(_ tag: Tag) {
        let query = Entry.tagEntriesTable
            .filter(Entry.idColumn == tag.id)
            .filter(Entry.entryColumn == self.entry.id)
            .delete()
        do {
            try self.entry.library.db!.run(query)
        } catch {print(error)}
        self.refresh()
    }
}

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
        let query = TagEntriesTable.table.select(*).filter(TagEntriesTable.entryId == self.entry.id)
        var tags: [Tag] = []
        do {
            for rawTag in try self.entry.library.db!.prepare(query) {
                let tag = self.entry.library.tags.getById(id: rawTag[TagEntriesTable.id])
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
        
        let query = TagEntriesTable.table.insert(TagEntriesTable.id <- tag.id, TagEntriesTable.entryId <- self.entry.id)
        do {
            try self.entry.library.db!.run(query)
        } catch {print(error)}
        self.refresh()
    }
    
    func remove(_ tag: Tag) {
        let query = TagEntriesTable.table
            .filter(TagEntriesTable.id == tag.id)
            .filter(TagEntriesTable.entryId == self.entry.id)
            .delete()
        do {
            try self.entry.library.db!.run(query)
        } catch {print(error)}
        self.refresh()
    }
}

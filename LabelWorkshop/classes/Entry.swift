import Foundation
import SQLite

class Entry {
    var path: String
    var id: Int
    var fullPath: URL?
    var tags: EntryTagManager!
    let library: Library
    
    static var tagEntriesTable: Table = Table("tag_entries")
    static var idColumn = Expression<Int>("tag_id")
    static var entryColumn = Expression<Int>("entry_id")
    
    init (library: Library, path: String, id: Int) {
        self.path = path
        self.library = library
        self.id = id
        if library.bookmark != nil { self.fullPath = library.bookmark?.appendingPathComponent(path) }
        self.tags = EntryTagManager(self)
    }
    
    @available(*, deprecated)
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
        } catch {print(error)}
        return tags
    }
    
    func getFields() -> [Field] {
        var fields: [Field] = []
        let query = Field.textFieldsTable
            .select(*).filter(Field.entryIdColumn == self.id)
        do {
            for rawField in try self.library.db!.prepare(query) {
                let field = Field(
                    id: rawField[Field.idColumn],
                    entryId: self.id,
                    name: rawField[Field.nameColumn],
                    entry: self,
                    value: rawField[Field.textValueColumn],
                )
                fields.append(field)
            }
        } catch {print(error)}
        return fields
    }
    
    func addField(_ type: FieldType) -> Field? {
        let query = Field.textFieldsTable.insert(
            Field.isMultilineColumn <- false,
            Field.entryIdColumn <- self.id,
            Field.nameColumn <- type.name,
            Field.textValueColumn <- ""
        )
        do {
            let id: Int64? = try self.library.db!.run(query)
            if let id = id {
                return Field(
                    id: Int(id),
                    entryId: self.id,
                    name: type.name,
                    entry: self,
                    value: ""
                )
            }
        } catch {print(error)}
        return nil
    }
    
    func deleteField(_ id: Int) throws {
        let query = Field.textFieldsTable
            .filter(Field.idColumn == id)
            .delete()
        try self.library.db!.run(query)
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
        } catch {print(error)}
    }
    
    @available(*, deprecated)
    func addTag(_ tag: Tag) {
        let query = Entry.tagEntriesTable.insert(Entry.idColumn <- tag.id, Entry.entryColumn <- self.id)
        do {
            try self.library.db!.run(query)
        } catch {print(error)}
    }
    
    @available(*, deprecated)
    func removeTag(_ tag: Tag) {
        let query = Entry.tagEntriesTable
            .filter(Entry.idColumn == tag.id)
            .filter(Entry.entryColumn == self.id)
            .delete()
        do {
            try self.library.db!.run(query)
        } catch {print(error)}
    }
    
    @available(*, deprecated)
    func containsAllTags(_ tags: [Tag]) -> Bool {
        let entryTags = self.getTags()
        for tag in tags {
            if !entryTags.contains(where: { $0.id == tag.id }) {
                return false
            }
        }
        return true
    }
}

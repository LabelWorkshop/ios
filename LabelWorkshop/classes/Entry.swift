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
    
    func getFields() -> [Field] {
        var fields: [Field] = []
        let query = Field.textFieldsTable
            .select(*).filter(Field.entryIdColumn == self.id)
        do {
            for rawField in try self.library.db!.prepare(query) {
                let field = Field(
                    id: rawField[Field.idColumn],
                    entryId: rawField[Field.entryIdColumn],
                    key: rawField[Field.typeColumn],
                    position: rawField[Field.positionColumn],
                    entry: self,
                    value: rawField[Field.textValueColumn],
                )
                fields.append(field)
            }
        } catch {}
        return fields
    }
    
    func addField(_ key: String) -> Field? {
        let position = (self.getFields()
            .filter { $0.key == key }
            .sorted{ $0.position < $1.position }
            .last?.position ?? -1) + 1
        let query = Field.textFieldsTable.insert(
            Field.typeColumn <- key,
            Field.entryIdColumn <- self.id,
            Field.positionColumn <- position,
            Field.textValueColumn <- ""
        )
        do {
            let id: Int64? = try self.library.db!.run(query)
            if let id = id {
                return Field(
                    id: Int(id),
                    entryId: self.id,
                    key: key,
                    position: position,
                    entry: self,
                    value: ""
                )
            }
        } catch {}
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
        } catch {}
    }
    
    func addTag(_ tag: Tag) {
        let query = Entry.tagEntriesTable.insert(Entry.idColumn <- tag.id, Entry.entryColumn <- self.id)
        do {
            try self.library.db!.run(query)
        } catch {}
    }
    
    func removeTag(_ tag: Tag) {
        let query = Entry.tagEntriesTable
            .filter(Entry.idColumn == tag.id)
            .filter(Entry.entryColumn == self.id)
            .delete()
        do {
            try self.library.db!.run(query)
        } catch {}
    }
}

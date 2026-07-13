import Foundation
import SQLite

class Entry {
    var path: String
    var id: Int
    var fullPath: URL?
    var tags: EntryTagManager!
    let library: Library
    
    init (library: Library, path: String, id: Int) {
        self.path = path
        self.library = library
        self.id = id
        if library.bookmark != nil { self.fullPath = library.bookmark?.appendingPathComponent(path) }
        self.tags = EntryTagManager(self)
    }
    
    @available(*, deprecated)
    func getTags() -> [Tag] {
        let query = TagEntriesTable.table.select(*).filter(TagEntriesTable.entryId == self.id)
        var tags: [Tag] = []
        do {
            for rawTag in try self.library.db!.prepare(query) {
                let tag = Tag.fetch(library: self.library, id: rawTag[EntriesTable.id])
                if let tag = tag {
                    tags.append(tag)
                }
            }
        } catch {print(error)}
        return tags
    }
    
    func getFields() -> [Field] {
        var fields: [Field] = []
        let query = TextFieldsTable.table
            .select(*).filter(TextFieldsTable.entryId == self.id)
        do {
            for rawField in try self.library.db!.prepare(query) {
                let field = Field(
                    id: rawField[TextFieldsTable.id],
                    entryId: self.id,
                    name: rawField[TextFieldsTable.name],
                    entry: self,
                    value: rawField[TextFieldsTable.value],
                )
                fields.append(field)
            }
        } catch {print(error)}
        return fields
    }
    
    func addField(_ type: FieldType) -> Field? {
        let query = TextFieldsTable.table.insert(
            TextFieldsTable.isMultiline <- false,
            TextFieldsTable.entryId <- self.id,
            TextFieldsTable.name <- type.name,
            TextFieldsTable.value <- ""
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
        let query = TextFieldsTable.table
            .filter(TextFieldsTable.id == id)
            .delete()
        try self.library.db!.run(query)
    }
    
    func delete() {
        let queries = [
            DateFieldsTable.table
                .filter(EntriesTable.id == self.id)
                .delete(),
            TextFieldsTable.table
                .filter(EntriesTable.id == self.id)
                .delete(),
            TagEntriesTable.table
                .filter(EntriesTable.id == self.id)
                .delete(),
            EntriesTable.table
                .filter(EntriesTable.id == self.id)
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
        let query = TagEntriesTable.table.insert(EntriesTable.id <- tag.id, TagEntriesTable.entryId <- self.id)
        do {
            try self.library.db!.run(query)
        } catch {print(error)}
    }
    
    @available(*, deprecated)
    func removeTag(_ tag: Tag) {
        let query = TagEntriesTable.table
            .filter(EntriesTable.id == tag.id)
            .filter(TagEntriesTable.entryId == self.id)
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

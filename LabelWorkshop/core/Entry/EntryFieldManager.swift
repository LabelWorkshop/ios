import SQLite
import Observation

@Observable
class EntryFieldManager {
    let entry: Entry
    var fields: [FieldEntry] = []
    var textFields: [TextFieldEntry] {
        // This will not fail.
        fields.filter { $0.type == .text } as! [TextFieldEntry]
    }
    
    init(_ entry: Entry) throws {
        self.entry = entry
        try self.refresh()
    }
    
    func refresh() throws {
        guard let db = self.entry.library.db else { throw LibraryError.databaseInvalid }
        var newFields: [FieldEntry] = []
        let query = TextFieldsTable.table
            .select(*).filter(TextFieldsTable.entryId == self.entry.id)
        for rawField in try db.prepare(query) {
            let fieldEntry = FieldEntry.get(
                id: rawField[TextFieldsTable.id],
                name: rawField[TextFieldsTable.name],
                entry: self.entry,
                type: .text
            )
            newFields.append(fieldEntry)
        }
        self.fields = newFields
    }
    
    func add(_ template: FieldTemplate) throws -> FieldEntry? {
        guard let db = self.entry.library.db else { throw LibraryError.databaseInvalid }
        var setters: [Setter] = [
            TextFieldsTable.entryId <- self.entry.id,
            TextFieldsTable.name <- template.name,
            TextFieldsTable.value <- ""
        ]
        if template.type == .text {
            setters.append(TextFieldsTable.isMultiline <- false)
        }
        let query = template.type.entriesTable.insert(setters)
        let id: Int64? = try db.run(query)
        if let id = id {
            let fieldEntry = FieldEntry.get(
                id: Int(id),
                name: template.name,
                entry: self.entry,
                type: template.type
            )
            fields.append(fieldEntry)
            return fieldEntry
        }
        return nil
    }
    
    func remove(field: FieldEntry) throws {
        guard let db = self.entry.library.db else { throw LibraryError.databaseInvalid }
        try db.run(field.type.entriesTable
            .filter(TextFieldsTable.id == field.id)
            .delete())
        self.fields.remove(at:
            self.fields.firstIndex(where: { $0 == field }) ?? -1
        )
    }
}

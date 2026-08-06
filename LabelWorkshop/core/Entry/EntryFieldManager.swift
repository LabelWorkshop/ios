import SQLite
import Observation

@Observable
class EntryFieldManager {
    let entry: Entry
    var fields: [Field] = []
    
    init(_ entry: Entry) throws {
        self.entry = entry
        try self.refresh()
    }
    
    func refresh() throws {
        guard let db = self.entry.library.db else { throw LibraryError.databaseInvalid }
        var newFields: [Field] = []
        let query = TextFieldsTable.table
            .select(*).filter(TextFieldsTable.entryId == self.entry.id)
        do {
            for rawField in try db.prepare(query) {
                let field = Field(
                    id: rawField[TextFieldsTable.id],
                    entryId: self.entry.id,
                    name: rawField[TextFieldsTable.name],
                    entry: self.entry,
                    value: rawField[TextFieldsTable.value],
                )
                newFields.append(field)
            }
        } catch {print(error)}
        self.fields = newFields
    }
    
    func add(_ template: FieldTemplate) throws -> Field? {
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
        do {
            let id: Int64? = try db.run(query)
            if let id = id {
                let newField = Field(
                    id: Int(id),
                    entryId: self.entry.id,
                    name: template.name,
                    entry: self.entry,
                    value: ""
                )
                fields.append(newField)
                return newField
            }
        } catch {print(error)}
        return nil
    }
    
    func remove(field: Field) throws {
        guard let db = self.entry.library.db else { throw LibraryError.databaseInvalid }
        guard let query = field.type?.type.table
            .filter(TextFieldsTable.id == field.id)
            .delete() else { throw LibraryError.databaseInvalid }
        try db.run(query)
        self.fields.remove(at:
            self.fields.firstIndex(where: { $0 == field }) ?? -1
        )
    }
}

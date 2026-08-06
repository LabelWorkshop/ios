import SQLite
import Observation

@Observable
class FieldTemplateManager {
    var library: Library
    var fieldTemplates: [FieldTemplate] = []
    
    init(library: Library) throws {
        self.library = library
        try self.refresh()
    }
    
    func refresh() throws {
        guard let db = self.library.db else { throw LibraryError.databaseInvalid }
        
        // Get Field Templates
        var newFieldTemplates: [FieldTemplate] = []
        for rawFieldTemplates in try db.prepare(TextFieldTemplatesTable.table) {
            newFieldTemplates.append(
                FieldTemplate(
                    id: rawFieldTemplates[TextFieldTemplatesTable.id],
                    name: rawFieldTemplates[TextFieldTemplatesTable.name]
                )
            )
        }
        for rawFieldTemplates in try db.prepare(DateFieldTemplatesTable.table) {
            newFieldTemplates.append(
                FieldTemplate(
                    id: rawFieldTemplates[DateFieldTemplatesTable.id],
                    name: rawFieldTemplates[DateFieldTemplatesTable.name]
                )
            )
        }
        self.fieldTemplates = newFieldTemplates
    }
}

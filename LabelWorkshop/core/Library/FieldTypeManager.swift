import SQLite
import Observation

@Observable
class FieldTypeManager {
    var library: Library
    var fieldTypes: [FieldType] = []
    
    init(library: Library) throws {
        self.library = library
        try self.refresh()
    }
    
    func refresh() throws {
        guard let db = self.library.db else { throw LibraryError.databaseInvalid }
        
        // Get Field Types
        var newFieldTypes: [FieldType] = []
        for rawFieldType in try db.prepare(TextFieldTemplatesTable.table) {
            newFieldTypes.append(
                FieldType(
                    id: rawFieldType[TextFieldTemplatesTable.id],
                    name: rawFieldType[TextFieldTemplatesTable.name]
                )
            )
        }
        self.fieldTypes = newFieldTypes
    }
}

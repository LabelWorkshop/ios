import SQLite
import Observation

@Observable
class FieldTemplateManager {
    var library: Library
    var fieldTemplates: [FieldTemplate] = []
    var dates: [FieldTemplate] {
        self.fieldTemplates.filter { $0.type == .date }
    }
    var texts: [FieldTemplate] {
        self.fieldTemplates.filter { $0.type == .text }
    }
    
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
                    name: rawFieldTemplates[TextFieldTemplatesTable.name],
                    type: .text
                )
            )
        }
        for rawFieldTemplates in try db.prepare(DateFieldTemplatesTable.table) {
            newFieldTemplates.append(
                FieldTemplate(
                    id: rawFieldTemplates[DateFieldTemplatesTable.id],
                    name: rawFieldTemplates[DateFieldTemplatesTable.name],
                    type: .date
                )
            )
        }
        self.fieldTemplates = newFieldTemplates
    }
    
    func getTemplateByTitle(title: String, type: FieldTemplateType) -> FieldTemplate? {
        self.fieldTemplates.filter{ field in
            field.name == title && field.type == type
        }.first
    }
}

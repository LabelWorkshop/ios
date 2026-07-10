import SQLite
import struct Foundation.Date

class FieldType: Identifiable {
    static let textFieldsTable: Table = Table("text_field_templates")
    
    static let idColumn: Expression = Expression<Int>("id")
    static let nameColumn: Expression = Expression<String>("name")
    static let isMultilineColumn: Expression = Expression<Bool>("is_multiline")
    
    let id: Int
    let name: String
    
    init(
        id: Int,
        name: String
    ) {
        self.id = id
        self.name = name
    }
}

class Field: Identifiable, Hashable {
    static func == (lhs: Field, rhs: Field) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static let textFieldsTable: Table = Table("text_fields")
    static let dateFieldsTable: Table = Table("datetime_fields")
    
    static let isMultilineColumn: Expression = Expression<Bool>("is_multiline")
    static let idColumn: Expression = Expression<Int>("id")
    static let nameColumn: Expression = Expression<String>("name")
    static let entryIdColumn: Expression = Expression<Int>("entry_id")
    static let textValueColumn: Expression = Expression<String?>("value")
    
    var id: Int
    var entryId: Int
    var name: String
    var value: String?
    var entry: Entry
    var type: FieldType?
    var text: String {
        get {
            value ?? ""
        }
        set {
            let query = Field.textFieldsTable
                .filter(Field.idColumn == self.id)
                .update(Field.textValueColumn <- newValue)
            do {
                try self.entry.library.db!.run(query)
                self.value = newValue
            } catch {print(error)}
        }
    }
    
    init(
        id: Int,
        entryId: Int,
        name: String,
        entry: Entry,
        value: String?
    ) {
        self.id = id
        self.entryId = entryId
        self.name = name
        self.value = value
        self.entry = entry
        self.type = entry.library.fieldTypes.first(where: {$0.id == id})
    }
}

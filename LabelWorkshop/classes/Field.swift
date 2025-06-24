import SQLite
import struct Foundation.Date

class FieldType {
    static let fieldTypesTable: Table = Table("value_type")
    
    static let keyColumn: Expression = Expression<String>("key")
    static let nameColumn: Expression = Expression<String>("name")
    static let positionColumn: Expression = Expression<Int>("position")
    static let typeColumn: Expression = Expression<String>("type")
    static let isDefaultColumn: Expression = Expression<Bool>("is_default")
    
    let key: String
    let name: String
    let type: String
    let isDefault: Bool
    let position: Int
    
    init(
        key: String,
        name: String,
        type: String,
        isDefault: Bool,
        position: Int
    ) {
        self.key = key
        self.isDefault = isDefault
        self.name = name
        self.type = type
        self.position = position
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
    
    static let idColumn: Expression = Expression<Int>("id")
    static let entryIdColumn: Expression = Expression<Int>("entry_id")
    static let positionColumn: Expression = Expression<Int>("position")
    static let typeColumn: Expression = Expression<String>("type_key")
    static let textValueColumn: Expression = Expression<String?>("value")
    
    var id: Int
    var entryId: Int
    var key: String
    var position: Int
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
            } catch {}
        }
    }
    var name: String {
        get {
            self.type?.name ?? self.key
        }
    }
    
    init(
        id: Int,
        entryId: Int,
        key: String,
        position: Int,
        entry: Entry,
        value: String?
    ) {
        self.id = id
        self.entryId = entryId
        self.key = key
        self.position = position
        self.value = value
        self.entry = entry
        self.type = entry.library.fieldTypes.first(where: {$0.key == key})
    }
}

import SQLite
import struct Foundation.Date

class FieldType: Identifiable {
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
            let query = TextFieldsTable.table
                .filter(TextFieldsTable.id == self.id)
                .update(TextFieldsTable.value <- newValue)
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

let LEGACY_FIELD_MAP = [
    0: ["type": "text", "name": "Title", "is_multiline": false],
    1: ["type": "text", "name": "Author", "is_multiline": false],
    2: ["type": "text", "name": "Artist", "is_multiline": false],
    3: ["type": "text", "name": "URL", "is_multiline": false],
    4: ["type": "text", "name": "Description", "is_multiline": true],
    5: ["type": "text", "name": "Notes", "is_multiline": true],
    9: ["type": "text", "name": "Collation", "is_multiline": false],
    10: ["type": "datetime", "name": "Date", "is_multiline": false],
    11: ["type": "datetime", "name": "Date Created"],
    12: ["type": "datetime", "name": "Date Modified"],
    13: ["type": "datetime", "name": "Date Taken"],
    14: ["type": "datetime", "name": "Date Published"],
    17: ["type": "text", "name": "Book", "is_multiline": false],
    18: ["type": "text", "name": "Comic", "is_multiline": false],
    19: ["type": "text", "name": "Series", "is_multiline": false],
    20: ["type": "text", "name": "Manga", "is_multiline": false],
    21: ["type": "text", "name": "Source", "is_multiline": false],
    22: ["type": "datetime", "name": "Date Uploaded"],
    23: ["type": "datetime", "name": "Date Released"],
    24: ["type": "text", "name": "Volume", "is_multiline": false],
    25: ["type": "text", "name": "Anthology", "is_multiline": false],
    26: ["type": "text", "name": "Magazine", "is_multiline": false],
    27: ["type": "text", "name": "Publisher", "is_multiline": false],
    28: ["type": "text", "name": "Guest Artist", "is_multiline": false],
    29: ["type": "text", "name": "Composer", "is_multiline": false],
    30: ["type": "text", "name": "Comments", "is_multiline": true],
]


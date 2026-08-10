import SQLite
import Observation
import struct Foundation.Date

enum FieldTemplateType {
    var table: Table {
        switch self {
        case .text: TextFieldTemplatesTable.table
        case .date: DateFieldTemplatesTable.table
        }
    }
    
    var entriesTable: Table {
        switch self {
        case .text: TextFieldsTable.table
        case .date: DateFieldsTable.table
        }
    }
    
    case text
    case date
}

class FieldTemplate: Identifiable {
    let id: Int
    let name: String
    let type: FieldTemplateType
    
    init(
        id: Int,
        name: String,
        type: FieldTemplateType
    ) {
        self.id = id
        self.name = name
        self.type = type
    }
}

class FieldEntry: Identifiable {
    var id: Int
    var name: String
    var entry: Entry
    var type: FieldTemplateType
    
    static func == (lhs: FieldEntry, rhs: FieldEntry) -> Bool {
        return lhs.type == rhs.type && lhs.id == rhs.id
    }
    
    init(id: Int, name: String, entry: Entry, type: FieldTemplateType) {
        self.id = id
        self.name = name
        self.entry = entry
        self.type = type
        do {
            try self.refresh()
        } catch {print(error)}
    }
    
    static func get(
        id: Int,
        name: String,
        entry: Entry,
        type: FieldTemplateType
    ) -> FieldEntry {
        switch type {
        case .text:
            return TextFieldEntry(id: id, name: name, entry: entry, type: type)
        case .date:
            return FieldEntry(id: id, name: name, entry: entry, type: type)
        }
    }
    
    func refresh() throws {}
}

class TextFieldEntry: FieldEntry {
    var value: String?
    var text: String {
        get {
            value ?? ""
        }
        set {
            let query = TextFieldsTable.table
                .filter(TextFieldsTable.id == self.id)
                .update(TextFieldsTable.value <- newValue)
            do {
                _ = try self.entry.library.withDatabase { db in
                    try db.run(query)
                }
                self.value = newValue
            } catch {print(error)}
        }
    }
    
    override func refresh() throws {
        if let db = self.entry.library.db {
            if let row = try db.pluck(TextFieldsTable.table
                .filter(TextFieldsTable.id == self.id)) {
                self.value = row[TextFieldsTable.value]
            }
        }
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


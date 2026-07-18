import Foundation
import SQLite

struct ColorNamespacesTable {
    static let table = Table("namespaces")
    static let namespace = Expression<String>("namespace")
    static let name = Expression<String>("name")
}

struct PreferenceTable {
    static let table = Table("preferences")
    static let key = Expression<String>("key")
    static let value = Expression<String>("value")
}

struct VersionTable {
    static let table = Table("versions")
    static let key = Expression<String>("key")
    static let value = Expression<Int>("value")
}

struct EntriesTable {
    static let table = Table("entries")
    static let path = Expression<String>("path")
    static let filename = Expression<String>("filename")
    static let id = Expression<Int>("id")
    static let suffix = Expression<String>("suffix")
    static let dateCreated = Expression<Date>("date_created")
}

struct SequenceTable {
    static let table = Table("sqlite_sequence")
    static let name = Expression<String?>("name")
    static let sequence = Expression<Int?>("seq")
}

struct TagEntriesTable {
    static let table = Table("tag_entries")
    static let id = Expression<Int>("tag_id")
    static let entryId = Expression<Int>("entry_id")
}

struct TagsTable {
    static let table: Table = Table("tags")
    static let id = Expression<Int>("id")
    static let name = Expression<String>("name")
    static let shorthand = Expression<String?>("shorthand")
    static let colorNamespace = Expression<String?>("color_namespace")
    static let colorSlug = Expression<String?>("color_slug")
    static let isCategory = Expression<Bool>("is_category")
    static let disambiguationId = Expression<Int?>("disambiguation_id")
    static let isHidden = Expression<Bool?>("is_hidden")
}

struct TagParentsTable {
    static let table = Table("tag_parents")
    static let childId = Expression<Int>("child_id")
    static let parentId = Expression<Int>("parent_id")
}

struct TagAliasesTable {
    static let table = Table("tag_aliases")
    static let name = Expression<String>("name")
    static let tagId = Expression<Int>("tag_id")
    static let id = Expression<Int>("id")
}

struct TagColorsTable {
    static let table = Table("tag_colors")
    static let slug = Expression<String>("slug")
    static let namespace = Expression<String>("namespace")
    static let primary = Expression<String>("primary")
    static let secondary = Expression<String?>("secondary")
    static let colorBorder = Expression<Bool>("color_border")
    static let name = Expression<String>("name")
}

struct TextFieldsTable {
    static let table = Table("text_fields")
    static let isMultiline = Expression<Bool>("is_multiline")
    static let id = Expression<Int>("id")
    static let name = Expression<String>("name")
    static let entryId = Expression<Int>("entry_id")
    static let value = Expression<String?>("value")
}

struct DateFieldsTable {
    static let table = Table("datetime_fields")
    static let id = Expression<Int>("id")
    static let name = Expression<String>("name")
    static let entryId = Expression<Int>("entry_id")
    static let value = Expression<String?>("value")
}

struct TextFieldTemplatesTable {
    static let table: Table = Table("text_field_templates")
    static let id = Expression<Int>("id")
    static let name = Expression<String>("name")
    static let isMultiline = Expression<Bool>("is_multiline")
}

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
    static var table: Table = Table("tags")
    static var id = Expression<Int>("id")
    static var name = Expression<String>("name")
    static var shorthand = Expression<String?>("shorthand")
    static var colorNamespace = Expression<String?>("color_namespace")
    static var colorSlug = Expression<String?>("color_slug")
    static var isCategory = Expression<Bool>("is_category")
    static var disambiguationId = Expression<Int?>("disambiguation_id")
    static var isHidden = Expression<Bool?>("is_hidden")
}

struct TagParentsTable {
    static var table = Table("tag_parents")
    static var childId = Expression<Int>("child_id")
    static var parentId = Expression<Int>("parent_id")
}

struct TagAliasesTable {
    static let table = Table("tag_aliases")
    static let name = Expression<String>("name")
    static let tagId = Expression<Int>("tag_id")
    static let id = Expression<Int>("id")
}

struct TagColorsTable {
    static var table = Table("tag_colors")
    static var slug = Expression<String>("slug")
    static var namespace = Expression<String>("namespace")
    static var primary = Expression<String>("primary")
    static var secondary = Expression<String?>("secondary")
    static var colorBorder = Expression<Bool>("color_border")
    static var name = Expression<String>("name")
}

struct TextFieldsTable {
    static let table = Table("text_fields")
    static let isMultiline: Expression = Expression<Bool>("is_multiline")
    static let id: Expression = Expression<Int>("id")
    static let name: Expression = Expression<String>("name")
    static let entryId: Expression = Expression<Int>("entry_id")
    static let value: Expression = Expression<String?>("value")
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
    static let id: Expression = Expression<Int>("id")
    static let name: Expression = Expression<String>("name")
    static let isMultiline: Expression = Expression<Bool>("is_multiline")
}

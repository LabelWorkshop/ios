import Foundation
import SQLite
import PathKit

enum LibraryError: Error {
    case databaseInvalid
    case databaseUnmigrateable
}

func loadBookmark(key: String) -> URL? {
    guard let data = UserDefaults.standard.data(forKey: key) else {
        return nil
    }

    var isStale = false
    do {
        let url = try URL(
            resolvingBookmarkData: data,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        if isStale {return nil}
        return url
    } catch {return nil}
}

extension Connection {
    public var legacyDatabaseVersion: Int {
        get { return Int((try? scalar("PRAGMA schema_version") as? Int64) ?? 0) }
        set { _ = try? run("PRAGMA schema_version = \(newValue)") }
    }
    
    public var databaseVersion: Int {
        get {
            if let row = try? self.pluck(Library.versionTable.filter(Library.versionKeyColumn == "CURRENT")) {
                return row[Library.versionValueColumn]
            }
            return 0
        }
        set { _ = Library.versionTable.filter(Library.versionKeyColumn == "CURRENT")
            .update(Library.versionValueColumn <- Int(newValue))
        }
    }
}

class Library: Hashable, Identifiable {
    static func == (lhs: Library, rhs: Library) -> Bool {
        return lhs.bookmarkKey == rhs.bookmarkKey
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(bookmarkKey)
    }
    
    var bookmarkKey: String
    var bookmark: URL?
    var db: Connection?
    var tagColors: TagColorManager!
    var fieldTypes: [FieldType] = []
    var ignoreList: String = ""
    var matcher: TSIgnoreMatcher?
    
    var tags: LibraryTagManager!
    
    var thumbnailCache: EntryThumbnailCache = EntryThumbnailCache()
    
    static var versionTable: Table = Table("versions")
    static var versionKeyColumn = Expression<String>("key")
    static var versionValueColumn = Expression<Int>("value")
    
    static var preferencesTable: Table = Table("preferences")
    static var preferenceKeyColumn = Expression<String>("key")
    static var preferenceValueColumn = Expression<String>("value")
    
    static var entriesTable: Table = Table("entries")
    static var pathColumn = Expression<String>("path")
    static var filenameColumn = Expression<String>("filename")
    static var entryIdColumn = Expression<Int>("id")
    
    static var sequenceTable = Table("sqlite_sequence")
    static var nameColumn = Expression<String?>("name")
    static var sequenceColumn = Expression<Int?>("seq")
    
    init(bookmarkKey: String) {
        self.bookmarkKey = bookmarkKey
        self.bookmark = loadBookmark(key: self.bookmarkKey)
        var isNew: Bool = false
        do {
            // Create TagStudio folder if not already created
            if let bookmark = bookmark {
                print(bookmark.appendingPathComponent(".TagStudio"))
                try FileManager.default.createDirectory(
                    at: bookmark.appendingPathComponent(".TagStudio"),
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                isNew = !FileManager.default.fileExists(atPath: bookmark.appendingPathComponent(".TagStudio/ts_library.sqlite").path)
            }
            // Inititalize Database
            let dbFile = self.bookmark?.appendingPathComponent(".TagStudio/ts_library.sqlite").absoluteString ?? ""
            self.db = try Connection(dbFile)
            try migrate(isNew: isNew)
            // Get Field Types
            for rawFieldType in try self.db!.prepare(FieldType.textFieldsTable) {
                self.fieldTypes.append(
                    FieldType(
                        id: rawFieldType[FieldType.idColumn],
                        name: rawFieldType[FieldType.nameColumn]
                    )
                )
            }
        } catch {print(error)}
        
        let ignoreFile = self.bookmark?.appendingPathComponent(".TagStudio/.ts_ignore")
        do {
            guard bookmark?.startAccessingSecurityScopedResource() == true else { throw LibraryError.databaseInvalid }
            defer { bookmark?.stopAccessingSecurityScopedResource() }
            if let ignoreFile = ignoreFile {
                let ignoreData = try Data(contentsOf: ignoreFile)
                ignoreList = String(data: ignoreData, encoding: .utf8) ?? ""
            }
        } catch {print(error)}
        
        ignoreList.append("\n.TagStudio\n.DS_Store")
        
        self.tagColors = TagColorManager(library: self)
        self.matcher = TSIgnoreMatcher(contents: ignoreList, baseURL: bookmark!)
        self.tags = LibraryTagManager(library: self)
    }
    
    func findNewFiles() throws -> [Path] {
        guard bookmark?.startAccessingSecurityScopedResource() == true else { throw LibraryError.databaseInvalid }
        defer { bookmark?.stopAccessingSecurityScopedResource() }
        
        let libPathString = bookmark?.path
        guard libPathString != nil else {return []}
        let libPath = Path(libPathString!)
        
        var allChildren: [Path] = try libPath.recursiveChildren()
        var newFiles: [Path] = []
        let entries: [Entry] = self.safeGetEntries()
        
        // Remove any paths that are already present as entries
        allChildren.removeAll { child in
            entries.contains { entry in
                return entry.fullPath == child.url
            }
        }
        
        for child in allChildren {
            if !(self.matcher?.isIgnored(relativePath: child.url.relativePath, isDirectory: child.isDirectory) ?? true) && !child.isDirectory {
                newFiles.append(child)
            }
        }
        
        return newFiles
    }
    
    func getName() -> (String) {
        guard bookmark?.startAccessingSecurityScopedResource() == true else { return "Unknown" }
        defer { bookmark?.stopAccessingSecurityScopedResource() }
        let name = bookmark?.absoluteString.removingPercentEncoding?.split(separator: "/").last ?? "Unknown"
        return String(name)
    }
    
    func getEntries(limit: Int? = nil) throws -> [Entry] {
        if self.db == nil { throw LibraryError.databaseInvalid }
        var entries: [Entry] = []
        do {
            for rawEntry in try self.db!.prepare(Library.entriesTable.limit(limit)) {
                let path: String = rawEntry[Library.pathColumn]
                let id: Int = rawEntry[Library.entryIdColumn]
                entries.append(Entry(library: self, path: path, id: id))
            }
        } catch {
            throw LibraryError.databaseInvalid
        }
        return entries
    }
    
    func safeGetEntries(limit: Int? = nil) -> [Entry] {
        do {
            return try self.getEntries()
        } catch {
            return []
        }
    }
    
    @available(*, deprecated)
    func newTag(_ name: String) -> Tag? {
        let sequenceQuery = Library.sequenceTable.filter(Library.nameColumn == "tags")
        do {
            if let raw = try self.db?.pluck(sequenceQuery) {
                let sequence = raw[Library.sequenceColumn]
                if let sequence = sequence {
                    let query = Tag.tagsTable.insert(
                        Tag.nameColumn <- name,
                        Tag.isCategoryColumn <- false,
                        Tag.isHiddenColumn <- false
                    )
                    try self.db?.run(query)
                    return Tag (
                        library: self,
                        name: name,
                        id: sequence,
                        colors: TagColor.none,
                        shorthand: nil,
                        isCategory: false,
                        disambiguationId: nil,
                        isHidden: false
                    )
                }
            }
        } catch {print(error)}
        return nil
    }
    
    private func migrate(isNew: Bool = false) throws {
        print("Starting migration for \"\(self.getName())\"")
        
        let migrations = [
            Migration(version: 8, legacyVersioning: true, run: migrateDB8),
            Migration(version: 9, legacyVersioning: true, run: migrateDB9),
            Migration(version: 100, legacyVersioning: true, run: migrateDB100),
            Migration(version: 101, legacyVersioning: false, run: migrateDB101),
            Migration(version: 102, legacyVersioning: false, run: migrateDB102),
            Migration(version: 103, legacyVersioning: false, run: migrateDB103)
        ]
        
        var databaseVersion: Int = 0
        
        if !isNew && self.db?.legacyDatabaseVersion ?? 0 < 8 {
            throw LibraryError.databaseUnmigrateable
        }
        
        if self.db?.databaseVersion == 0 {
            databaseVersion = self.db?.legacyDatabaseVersion ?? 0
        } else {
            databaseVersion = self.db?.databaseVersion ?? 0
        }
        
        print("DB Version: \(databaseVersion)")
        
        if !isNew && databaseVersion == 0 {throw LibraryError.databaseUnmigrateable}
        
        var skip = false
        
        for migration in migrations {
            if !(databaseVersion > migration.version) && !skip {
                do {
                    try migration.run()
                    print("Migrated to version \(migration.version)")
                } catch {
                    print("Migration to version \(migration.version) failed")
                    print(error)
                    skip = true
                }
                if migration.legacyVersioning {
                    self.db?.legacyDatabaseVersion = migration.version
                } else {
                    self.db?.databaseVersion = migration.version
                }
            }
        }
    }
    
    /// Create Database starting at version 8
    private func migrateDB8() throws {
        var executions: [Insert] = []
        try self.db?.execute("""
        CREATE TABLE namespaces (
            namespace VARCHAR NOT NULL, 
            name VARCHAR NOT NULL, 
            PRIMARY KEY (namespace)
        );
        CREATE TABLE folders (
            id INTEGER NOT NULL, 
            path VARCHAR NOT NULL, 
            uuid VARCHAR NOT NULL, 
            PRIMARY KEY (id), 
            UNIQUE (path), 
            UNIQUE (uuid)
        );
        CREATE TABLE value_type (
            "key" VARCHAR NOT NULL, 
            name VARCHAR NOT NULL, 
            type VARCHAR(9) NOT NULL, 
            is_default BOOLEAN NOT NULL, 
            position INTEGER NOT NULL, 
            PRIMARY KEY ("key")
        );
        CREATE TABLE preferences (
            "key" VARCHAR NOT NULL, 
            value JSON NOT NULL, 
            PRIMARY KEY ("key")
        );
        CREATE TABLE tag_colors (
            slug VARCHAR NOT NULL, 
            namespace VARCHAR NOT NULL, 
            name VARCHAR NOT NULL, 
            "primary" VARCHAR NOT NULL, 
            secondary VARCHAR, 
            color_border BOOLEAN NOT NULL, 
            PRIMARY KEY (slug, namespace), 
            FOREIGN KEY(namespace) REFERENCES namespaces (namespace)
        );
        CREATE TABLE entries (
            id INTEGER NOT NULL, 
            folder_id INTEGER NOT NULL, 
            path VARCHAR NOT NULL, 
            suffix VARCHAR NOT NULL, 
            date_created DATETIME, 
            date_modified DATETIME, 
            date_added DATETIME, 
            PRIMARY KEY (id), 
            FOREIGN KEY(folder_id) REFERENCES folders (id), 
            UNIQUE (path)
        );
        CREATE TABLE boolean_fields (
            value BOOLEAN NOT NULL, 
            id INTEGER NOT NULL, 
            type_key VARCHAR NOT NULL, 
            entry_id INTEGER NOT NULL, 
            position INTEGER NOT NULL, 
            PRIMARY KEY (id), 
            FOREIGN KEY(type_key) REFERENCES value_type ("key"), 
            FOREIGN KEY(entry_id) REFERENCES entries (id)
        );
        CREATE TABLE text_fields (
            value VARCHAR, 
            id INTEGER NOT NULL, 
            type_key VARCHAR NOT NULL, 
            entry_id INTEGER NOT NULL, 
            position INTEGER NOT NULL, 
            PRIMARY KEY (id), 
            FOREIGN KEY(type_key) REFERENCES value_type ("key"), 
            FOREIGN KEY(entry_id) REFERENCES entries (id)
        );
        CREATE TABLE datetime_fields (
            value VARCHAR, 
            id INTEGER NOT NULL, 
            type_key VARCHAR NOT NULL, 
            entry_id INTEGER NOT NULL, 
            position INTEGER NOT NULL, 
            PRIMARY KEY (id), 
            FOREIGN KEY(type_key) REFERENCES value_type ("key"), 
            FOREIGN KEY(entry_id) REFERENCES entries (id)
        );
        CREATE TABLE tags (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, 
            name VARCHAR NOT NULL, 
            shorthand VARCHAR, 
            color_namespace VARCHAR, 
            color_slug VARCHAR, 
            is_category BOOLEAN NOT NULL, 
            icon VARCHAR, 
            disambiguation_id INTEGER, 
            FOREIGN KEY(color_namespace, color_slug) REFERENCES tag_colors (namespace, slug)
        );
        CREATE TABLE tag_parents (
            parent_id INTEGER NOT NULL, 
            child_id INTEGER NOT NULL, 
            PRIMARY KEY (parent_id, child_id), 
            FOREIGN KEY(parent_id) REFERENCES tags (id), 
            FOREIGN KEY(child_id) REFERENCES tags (id)
        );
        CREATE TABLE tag_entries (
            tag_id INTEGER NOT NULL, 
            entry_id INTEGER NOT NULL, 
            PRIMARY KEY (tag_id, entry_id), 
            FOREIGN KEY(tag_id) REFERENCES tags (id), 
            FOREIGN KEY(entry_id) REFERENCES entries (id)
        );
        CREATE TABLE tag_aliases (
            id INTEGER NOT NULL, 
            name VARCHAR NOT NULL, 
            tag_id INTEGER NOT NULL, 
            PRIMARY KEY (id), 
            FOREIGN KEY(tag_id) REFERENCES tags (id)
        );
        """)
        
        let insertTagSequence = Library.sequenceTable.insert(
            Library.nameColumn <- "tags",
            Library.sequenceColumn <- 999
        )
        
        let insertNamespace1 = ColorNamespacesTable.table.insert(
            ColorNamespacesTable.namespace <- "tagstudio-standard",
            ColorNamespacesTable.name <- "TagStudio Standard"
        )
        
        let insertNamespace2 = ColorNamespacesTable.table.insert(
            ColorNamespacesTable.namespace <- "tagstudio-pastels",
            ColorNamespacesTable.name <- "TagStudio Pastels"
        )
        
        let insertNamespace3 = ColorNamespacesTable.table.insert(
            ColorNamespacesTable.namespace <- "tagstudio-shades",
            ColorNamespacesTable.name <- "TagStudio Shades"
        )
        
        let insertNamespace4 = ColorNamespacesTable.table.insert(
            ColorNamespacesTable.namespace <- "tagstudio-earth-tones",
            ColorNamespacesTable.name <- "TagStudio Earth Tones"
        )
        
        let insertNamespace5 = ColorNamespacesTable.table.insert(
            ColorNamespacesTable.namespace <- "tagstudio-grayscale",
            ColorNamespacesTable.name <- "TagStudio Grayscale"
        )
        
        let insertNamespace6 = ColorNamespacesTable.table.insert(
            ColorNamespacesTable.namespace <- "tagstudio-neon",
            ColorNamespacesTable.name <- "TagStudio Neon"
        )
        
        for color in TagColor.defaults {
            let insertColor = TagColor.tagColorsTable.insert(
                TagColor.colorBorderColumn <- color["color_border"] as! Bool,
                TagColor.nameColumn <- color["name"] as! String,
                TagColor.namespaceColumn <- color["namespace"] as! String,
                TagColor.primaryColumn <- color["primary"] as! String,
                TagColor.secondaryColumn <- color["secondary"] as? String,
                TagColor.slugColumn <- color["slug"] as! String
            )
            executions.append(insertColor)
        }
        
        let insertArchiveTag = Tag.tagsTable.insert(
            Tag.idColumn <- 0,
            Tag.nameColumn <- "Archived",
            Tag.tagColorNamespaceColumn <- "tagstudio-standard",
            Tag.tagColorSlugColumn <- "red",
            Tag.isCategoryColumn <- false
        )
        
        let insertFavoriteTag = Tag.tagsTable.insert(
            Tag.idColumn <- 1,
            Tag.nameColumn <- "Favorite",
            Tag.tagColorNamespaceColumn <- "tagstudio-standard",
            Tag.tagColorSlugColumn <- "yellow",
            Tag.isCategoryColumn <- false
        )
        
        let insertMetaTagsTag = Tag.tagsTable.insert(
            Tag.idColumn <- 2,
            Tag.nameColumn <- "Meta Tags",
            Tag.isCategoryColumn <- true
        )
        
        let insertArchiveAlias1 = TagAlias.tagAliasesTable.insert(
            TagAlias.idColumn <- 1,
            TagAlias.nameColumn <- "Archive",
            TagAlias.tagIdColumn <- 0
        )
        
        let insertMetaTagsAlias1 = TagAlias.tagAliasesTable.insert(
            TagAlias.idColumn <- 2,
            TagAlias.nameColumn <- "Meta",
            TagAlias.tagIdColumn <- 2
        )
        
        let insertMetaTagsAlias2 = TagAlias.tagAliasesTable.insert(
            TagAlias.idColumn <- 3,
            TagAlias.nameColumn <- "Meta Tag",
            TagAlias.tagIdColumn <- 2
        )
           
        let insertFavoritesAlias1 = TagAlias.tagAliasesTable.insert(
            TagAlias.idColumn <- 4,
            TagAlias.nameColumn <- "Favorited",
            TagAlias.tagIdColumn <- 1
        )
        
        let insertFavoritesAlias2 = TagAlias.tagAliasesTable.insert(
            TagAlias.idColumn <- 5,
            TagAlias.nameColumn <- "Favorites",
            TagAlias.tagIdColumn <- 1
        )
        
        let insertFavoritesParent = Tag.tagParentsTable.insert(
            Tag.parentIdColumn <- 1,
            Tag.childIdColumn <- 2
        )
        
        let insertArchiveParent = Tag.tagParentsTable.insert(
            Tag.parentIdColumn <- 0,
            Tag.childIdColumn <- 2
        )
        
        // NOTE: value_type table skipped as it gets removed in a later db version
        
        executions.append(contentsOf: [
            insertTagSequence,
            insertNamespace1,
            insertNamespace2,
            insertNamespace3,
            insertNamespace4,
            insertNamespace5,
            insertNamespace6,
            insertArchiveTag,
            insertFavoriteTag,
            insertMetaTagsTag,
            insertArchiveAlias1,
            insertMetaTagsAlias1,
            insertMetaTagsAlias2,
            insertFavoritesAlias1,
            insertFavoritesAlias2,
            insertFavoritesParent,
            insertArchiveParent
        ])
        
        for execution in executions {
            try self.db?.run(execution)
        }
    }
    
    /// Migrate to database version 9
    private func migrateDB9() throws {
        // Add filename column to entries table
        try self.db?.execute("ALTER TABLE entries ADD COLUMN filename TEXT NOT NULL DEFAULT ''")
        
        // Populate filename column
        try self.safeGetEntries().forEach { entry in
            let sqlEntry = Library.entriesTable.filter(Library.entryIdColumn == entry.id)
            try self.db?.run(sqlEntry.update(Library.filenameColumn <- entry.fullPath?.lastPathComponent ?? ""))
        }
    }
    
    /// Migrate to database version 100
    private func migrateDB100() throws {
        if let tagParents = try self.db?.prepare(Tag.tagParentsTable.select(*)) {
            for tagParent in tagParents {
                try self.db?.run(Tag.tagParentsTable
                    .select(*)
                    .filter(Tag.childIdColumn == tagParent[Tag.childIdColumn])
                    .filter(Tag.parentIdColumn == tagParent[Tag.parentIdColumn])
                    .update(Tag.childIdColumn <- tagParent[Tag.parentIdColumn],
                            Tag.parentIdColumn <- tagParent[Tag.childIdColumn]))
            }
        }
    }
    
    /// Migrate to database version 101
    private func migrateDB101() throws {
        let createVersions = Library.versionTable.create { table in
            table.column(Library.versionKeyColumn, primaryKey: true)
            table.column(Library.versionValueColumn, defaultValue: 0)
        }
        let insertVersion = Library.versionTable.insert(Library.versionKeyColumn <- "CURRENT", Library.versionValueColumn <- 101)
        try self.db?.run(createVersions)
        try self.db?.run(insertVersion)
    }
    
    /// Migrate to database version 102
    private func migrateDB102() throws {
        // Delete TagParents with no existing parent
        do {
            let tagParents = try self.db?.prepare(Tag.tagParentsTable.select(Tag.parentIdColumn, Tag.childIdColumn))
            
            let validTagIds = try db?.prepare(
                Tag.tagsTable.select(Tag.idColumn)
            ).map { $0[Tag.idColumn] }
            
            guard let validTagIds, let tagParents else { throw LibraryError.databaseUnmigrateable }
            
            
            let tagParentRows = Array(tagParents)
            
            for tagParent in tagParentRows {
                let isInvalid = validTagIds.filter { tagId in
                    tagId == tagParent[Tag.parentIdColumn]
                }.isEmpty
                
                if isInvalid {
                    try self.db?.run(
                        Tag.tagParentsTable
                        .filter(Tag.childIdColumn == tagParent[Tag.childIdColumn])
                        .filter(Tag.parentIdColumn == tagParent[Tag.parentIdColumn])
                        .delete()
                    )
                }
            }
            
        } catch {print(error)}
    }
    
    /// Migrate to database version 103
    private func migrateDB103() throws {
        try self.db?.execute("ALTER TABLE tags ADD COLUMN is_hidden BOOLEAN NOT NULL DEFAULT 0")
        try self.db?.run(Tag.tagsTable.filter(Tag.idColumn == 0).update(Tag.isHiddenColumn <- true))
    }
    
    /// Migrate to database version 104
    private func migrateDB104() throws {
        throw LibraryError.databaseInvalid // NOT COMPLETE SEE BELOW
        // TODO: ADD TSIGNORE MIGRATION
        do {
            try self.db?.execute("DROP TABLE preferences")
        } catch {print(error)}
    }
    
    /// Migrate to database version 200 UNCOMPLETE
    private func migrateDB200() throws {
        do {
            // Drop unused tables
            try self.db?.execute("DROP TABLE boolean_fields")
            try self.db?.execute("DROP TABLE value_type")
            
            // Add name to text_fields and datetime_fields
            try self.db?.execute("ALTER TABLE text_fields ADD COLUMN name VARCHAR DEFAULT \"\"")
            try self.db?.execute("ALTER TABLE datetime_fields ADD COLUMN name VARCHAR DEFAULT \"\"")
            
            // Drop unused position column
            try self.db?.execute("ALTER TABLE datetime_fields DROP COLUMN position")
            try self.db?.execute("ALTER TABLE text_fields DROP COLUMN position")
            
            // Add is_multiline column to text_fields
            try self.db?.execute("ALTER TABLE text_fields ADD COLUMN is_multiline BOOLEAN NOT NULL DEFAULT 0")
            
            // Move values from "type_key" to "name"
            try self.db?.execute("UPDATE text_fields SET name = type_key")
            try self.db?.execute("UPDATE datetime_fields SET name = type_key")
            
            // Change name values to title case
            // The only exception being URL field
            let textFields = try self.db?.prepare(Field.textFieldsTable)
            for textField in textFields! {
                try self.db?.run(Field.textFieldsTable.update(Field.nameColumn <- textField[Field.nameColumn].capitalized.replacingOccurrences(of: "Url", with: "URL")))
            }
            
            // Add correct is_multiline value to text_fields
            var inproperFieldNames: [String] = []
            for field in LEGACY_FIELD_MAP.values {
                if field["is_multiline"] as! Bool {
                    inproperFieldNames.append(field["name"] as! String)
                }
            }
            for inproperFieldName in inproperFieldNames {
                try self.db?.run(Field.textFieldsTable.select(Field.nameColumn == inproperFieldName).update(Field.isMultilineColumn <- true))
            }
            
            // Repair legacy Description fields to use multiline
            try self.db?.run(Field.textFieldsTable.select(Field.nameColumn == "Description").select(Field.isMultilineColumn == false).update(Field.isMultilineColumn <- true))
            
            // Repair legacy Comments fields to use multiline
            try self.db?.run(Field.textFieldsTable.select(Field.nameColumn == "Comments").select(Field.isMultilineColumn == false).update(Field.isMultilineColumn <- true))
            
            // Add default field templates
            
            
            // Add indices for preformance
            try self.db?.execute("CREATE INDEX IF NOT EXISTS idx_tags_name_shorthand ON tags (name, shorthand)")
            try self.db?.execute("CREATE INDEX IF NOT EXISTS idx_tag_parents_child_id ON tag_parents (child_id)")
            try self.db?.execute("CREATE INDEX IF NOT EXISTS idx_tag_entries_entry_id ON tag_entries (entry_id)")
            
            print("Migration 200 Complete")
            
        } catch {print(error)}
    }
}


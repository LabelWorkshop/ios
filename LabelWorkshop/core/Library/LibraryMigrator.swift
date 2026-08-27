import SQLite
import Foundation
import UIKit // Required for NSDataAsset
import Observation

enum MigrationState {
    case Unknown
    case MigrationNotRequired
    case MigrationInProgress
    case MigrationComplete
    case MigrationFailed
}

enum MigrationDebug {
    case Default
    case Delay
    case Crash
}

struct Migration {
    let version: Int
    let legacyVersioning: Bool
    let run: (Connection) throws -> Void
}

@Observable
class LibraryMigrator {
    let library: Library
    
    var percentage = 0.0
    
    var state: MigrationState = .Unknown
    var debug: MigrationDebug = .Default
    
    init(library: Library) {
        self.library = library
    }
    
    func backupDB() async throws {
        guard library.bookmark.startAccessingSecurityScopedResource() else { throw LibraryError.databaseInvalid }
        defer { library.bookmark.stopAccessingSecurityScopedResource() }
        
        let backupPath = library.bookmark.appendingPathComponent(".TagStudio/ts_library.sqlite.bak")
        let backupDB = try Connection(backupPath.path)
        
        let _ = try library.db.backup(usingConnection: backupDB)
        try backupDB.vacuum()
    }
    
    func migrate() async throws {
        guard self.state == .Unknown else {return}
        print("Starting migration for \"\(library.getName())\"")
        
        let migrations = [
            Migration(version: 8, legacyVersioning: true, run: migrateDB8),
            Migration(version: 9, legacyVersioning: true, run: migrateDB9),
            Migration(version: 100, legacyVersioning: true, run: migrateDB100),
            Migration(version: 101, legacyVersioning: false, run: migrateDB101),
            Migration(version: 102, legacyVersioning: false, run: migrateDB102),
            Migration(version: 103, legacyVersioning: false, run: migrateDB103),
            Migration(version: 104, legacyVersioning: false, run: migrateDB104),
            Migration(version: 200, legacyVersioning: false, run: migrateDB200),
            Migration(version: 201, legacyVersioning: false, run: migrateDB201),
            Migration(version: 202, legacyVersioning: false, run: migrateDB202),
            Migration(version: 300, legacyVersioning: false, run: migrateDB300)
        ]
        var requiedMigrations: [Migration] = []
        
        var databaseVersion: Int = 0
        
        if !library.isNew && library.db.legacyDatabaseVersion < 8 {
            throw LibraryError.databaseUnmigrateable
        }
        
        if library.db.databaseVersion == 0 {
            databaseVersion = library.db.legacyDatabaseVersion
        } else {
            databaseVersion = library.db.databaseVersion
        }
        
        print("DB Version: \(databaseVersion)")
        
        if !library.isNew && databaseVersion == 0 {throw LibraryError.databaseUnmigrateable}
        
        for migration in migrations {
            if !(databaseVersion >= migration.version) {
                requiedMigrations.append(migration)
            }
        }
        if requiedMigrations.isEmpty {
            self.state = .MigrationNotRequired
            return
        } else {
            try await self.backupDB()
            self.state = .MigrationInProgress
        }
            
        var i = 1
        for migration in requiedMigrations {
            if self.debug == .Delay {
                try await Task.sleep(for: .seconds(2))
            }
            do {
                if self.debug == .Crash {
                    throw LibraryError.databaseUnmigrateable
                }
                try library.db.transaction {
                    try migration.run(library.db)
                    if migration.legacyVersioning {
                        library.db.legacyDatabaseVersion = migration.version
                    } else {
                        library.db.databaseVersion = migration.version
                    }
                }
                print("Migrated to version \(migration.version)")
            } catch {
                print("Migration to version \(migration.version) failed")
                self.state = .MigrationFailed
                throw error
            }
            await MainActor.run { [i, requiedMigrations] in
                self.percentage = Double(i) / Double(requiedMigrations.count) * 100
            }
            i+=1
        }
        if state == .MigrationFailed {return}
        await MainActor.run {
            self.state = .MigrationComplete
            self.percentage = 100
        }
    }
    
    /// Create Database starting at version 8
    private func migrateDB8(db: Connection) throws {
        var executions: [Insert] = []
        try db.execute("""
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
        
        let insertTagSequence = SequenceTable.table.insert(
            SequenceTable.name <- "tags",
            SequenceTable.sequence <- 999
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
            if let colorBorder = color["color_border"] as? Bool,
               let name = color["name"] as? String,
               let namespace = color["namespace"] as? String,
               let primary = color["primary"] as? String,
               let slug = color["slug"] as? String
            {
                let insertColor = TagColorsTable.table.insert(
                    TagColorsTable.colorBorder <- colorBorder,
                    TagColorsTable.name <- name,
                    TagColorsTable.namespace <- namespace,
                    TagColorsTable.primary <- primary,
                    TagColorsTable.secondary <- color["secondary"] as? String,
                    TagColorsTable.slug <- slug
                )
                executions.append(insertColor)
            } else {
                throw LibraryError.databaseUnmigrateable
            }
        }
        
        let insertArchiveTag = TagsTable.table.insert(
            TagsTable.id <- 0,
            TagsTable.name <- "Archived",
            TagsTable.colorNamespace <- "tagstudio-standard",
            TagsTable.colorSlug <- "red",
            TagsTable.isCategory <- false
        )
        
        let insertFavoriteTag = TagsTable.table.insert(
            TagsTable.id <- 1,
            TagsTable.name <- "Favorite",
            TagsTable.colorNamespace <- "tagstudio-standard",
            TagsTable.colorSlug <- "yellow",
            TagsTable.isCategory <- false
        )
        
        let insertMetaTagsTag = TagsTable.table.insert(
            TagsTable.id <- 2,
            TagsTable.name <- "Meta Tags",
            TagsTable.isCategory <- true
        )
        
        let insertArchiveAlias1 = TagAliasesTable.table.insert(
            TagAliasesTable.id <- 1,
            TagAliasesTable.name <- "Archive",
            TagAliasesTable.tagId <- 0
        )
        
        let insertMetaTagsAlias1 = TagAliasesTable.table.insert(
            TagAliasesTable.id <- 2,
            TagAliasesTable.name <- "Meta",
            TagAliasesTable.tagId <- 2
        )
        
        let insertMetaTagsAlias2 = TagAliasesTable.table.insert(
            TagAliasesTable.id <- 3,
            TagAliasesTable.name <- "Meta Tag",
            TagAliasesTable.tagId <- 2
        )
           
        let insertFavoritesAlias1 = TagAliasesTable.table.insert(
            TagAliasesTable.id <- 4,
            TagAliasesTable.name <- "Favorited",
            TagAliasesTable.tagId <- 1
        )
        
        let insertFavoritesAlias2 = TagAliasesTable.table.insert(
            TagAliasesTable.id <- 5,
            TagAliasesTable.name <- "Favorites",
            TagAliasesTable.tagId <- 1
        )
        
        let insertFavoritesParent = TagParentsTable.table.insert(
            TagParentsTable.parentId <- 1,
            TagParentsTable.childId <- 2
        )
        
        let insertArchiveParent = TagParentsTable.table.insert(
            TagParentsTable.parentId <- 0,
            TagParentsTable.childId <- 2
        )
        
        let insertPreference1 = PreferenceTable.table.insert(
            PreferenceTable.key <- "EXTENSION_LIST",
            PreferenceTable.value <- "[\".json\", \".xmp\", \".aae\"]"
        )
        
        let insertPreference2 = PreferenceTable.table.insert(
            PreferenceTable.key <- "IS_EXCLUDE_LIST",
            PreferenceTable.value <- "true"
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
            insertArchiveParent,
            insertPreference1,
            insertPreference2
        ])
        
        for execution in executions {
            try db.run(execution)
        }
    }
    
    /// Migrate to database version 9
    private func migrateDB9(db: Connection) throws {
        // Add filename column to entries table
        try db.execute("ALTER TABLE entries ADD COLUMN filename TEXT NOT NULL DEFAULT ''")
        
        // Populate filename column
        for entry in try db.prepare(EntriesTable.table.select(*)) {
            let sqlEntry = EntriesTable.table.filter(EntriesTable.id == entry[EntriesTable.id])
            let filename = URL(fileURLWithPath: entry[EntriesTable.path]).lastPathComponent
            try db.run(sqlEntry.update(EntriesTable.filename <- filename))
        }
    }
    
    /// Migrate to database version 100
    private func migrateDB100(db: Connection) throws {
        let tagParentsStmt = try db.prepare(TagParentsTable.table.select(*))
        let tagParents = Array(tagParentsStmt)
        
        for tagParent in tagParents {
            try db.run(TagParentsTable.table
                .select(*)
                .filter(TagParentsTable.childId == tagParent[TagParentsTable.childId])
                .filter(TagParentsTable.parentId == tagParent[TagParentsTable.parentId])
                .update(TagParentsTable.childId <- tagParent[TagParentsTable.parentId],
                        TagParentsTable.parentId <- tagParent[TagParentsTable.childId]))
        }
    }
    
    /// Migrate to database version 101
    private func migrateDB101(db: Connection) throws {
        let createVersions = VersionTable.table.create { table in
            table.column(VersionTable.key, primaryKey: true)
            table.column(VersionTable.value, defaultValue: 0)
        }
        let insertVersion = VersionTable.table.insert(VersionTable.key <- "CURRENT", VersionTable.value <- 101)
        try db.run(createVersions)
        try db.run(insertVersion)
    }
    
    /// Migrate to database version 102
    private func migrateDB102(db: Connection) throws {
        // Delete TagParents with no existing parent
        try removeTagParentsOrphans(TagParentsTable.parentId, db: db)
    }
    
    private func removeTagParentsOrphans(_ expression: SQLite.Expression<Int>, db: Connection) throws {
        let tagParents = try db.prepare(TagParentsTable.table.select(TagParentsTable.parentId, TagParentsTable.childId))
        
        let validTagIds = try db.prepare(
            TagsTable.table.select(TagsTable.id)
        ).map { $0[TagsTable.id] }
        
        let tagParentRows = Array(tagParents)
        
        for tagParent in tagParentRows {
            let isInvalid = validTagIds.filter { tagId in
                tagId == tagParent[expression]
            }.isEmpty
            
            if isInvalid {
                try db.run(
                    TagParentsTable.table
                        .filter(TagParentsTable.childId == tagParent[TagParentsTable.childId])
                        .filter(TagParentsTable.parentId == tagParent[TagParentsTable.parentId])
                        .delete()
                )
            }
        }
    }
    
    /// Migrate to database version 103
    private func migrateDB103(db: Connection) throws {
        try db.execute("ALTER TABLE tags ADD COLUMN is_hidden BOOLEAN NOT NULL DEFAULT 0")
        try db.run(TagsTable.table.filter(TagsTable.id == 0).update(TagsTable.isHidden <- true))
    }
    
    /// Migrate to database version 104
    private func migrateDB104(db: Connection) throws {
        let isExcludeRow = try db.prepare("SELECT value FROM preferences WHERE key = 'IS_EXCLUDE_LIST'").makeIterator().next()
        let isExcludeValue = isExcludeRow?[0] as? String
        
        var extensionsValue = "[]"
        let extensionsRow = try db.prepare("SELECT value FROM preferences WHERE key = 'EXTENSION_LIST'")
        for row in extensionsRow {
            extensionsValue = row[0] as? String ?? "[]"
        }
        
        let extensions = try JSONDecoder().decode([String].self, from: Data(extensionsValue.utf8))
        
        var output = ""
        
        if let tsIgnoreTemplateAsset = NSDataAsset(name: "ts_ignore_template") {
            output.append(String(data: tsIgnoreTemplateAsset.data, encoding: .utf8) ?? "")
        }
        
        var prefix = ""
        if isExcludeValue == "false" {
            prefix = "!"
            output.append("*\n")
        }
        output.append("\n")
        for fileExtension in extensions {
            output.append("\(prefix)*.\(fileExtension.replacingOccurrences(of: ".", with: ""))\n")
        }
        
        let ignoreFile = library.bookmark.appendingPathComponent(".TagStudio/.ts_ignore")
        try output.write(to: ignoreFile, atomically: true, encoding: .utf8)
        
        try db.execute("DROP TABLE preferences")
    }
    
    /// Migrate to database version 200
    private func migrateDB200(db: Connection) throws {
        try db.execute("""
        CREATE TABLE text_field_templates (
            is_multiline BOOLEAN NOT NULL,
            id INTEGER NOT NULL,
            name VARCHAR NOT NULL,
            PRIMARY KEY (id)
        );
        CREATE TABLE datetime_field_templates (
            id INTEGER NOT NULL,
            name VARCHAR NOT NULL,
            PRIMARY KEY (id)
        );
    """)
        
        // Drop unused tables
        try db.execute("DROP TABLE IF EXISTS boolean_fields")
        try db.execute("DROP TABLE IF EXISTS value_type")
        
        // Add name to text_fields and datetime_fields
        try db.execute("ALTER TABLE text_fields ADD COLUMN name VARCHAR DEFAULT \"\"")
        try db.execute("ALTER TABLE datetime_fields ADD COLUMN name VARCHAR DEFAULT \"\"")
        
        // Drop unused position column
        try db.execute("ALTER TABLE datetime_fields DROP COLUMN position")
        try db.execute("ALTER TABLE text_fields DROP COLUMN position")
        
        // Add is_multiline column to text_fields
        try db.execute("ALTER TABLE text_fields ADD COLUMN is_multiline BOOLEAN NOT NULL DEFAULT 0")
        
        // Move values from "type_key" to "name"
        try db.execute("UPDATE text_fields SET name = type_key")
        try db.execute("UPDATE datetime_fields SET name = type_key")
        
        // Change name values to title case
        // The only exception being URL field
        let textFields = try db.prepare(TextFieldsTable.table)
        for textField in textFields {
            try db.run(TextFieldsTable.table.update(TextFieldsTable.name <- textField[TextFieldsTable.name].capitalized.replacingOccurrences(of: "Url", with: "URL")))
        }
        
        // Add correct is_multiline value to text_fields
        var inproperFieldNames: [String] = []
        for field in LEGACY_FIELD_MAP.values {
            if field["type"] as? String == "text" {
                if let isMultiline = field["is_multiline"] as? Bool, let fieldName = field["name"] as? String {
                    if isMultiline {
                        inproperFieldNames.append(fieldName)
                    }
                } else {
                    throw LibraryError.databaseUnmigrateable
                }
            }
        }
        for inproperFieldName in inproperFieldNames {
            try db.run(TextFieldsTable.table.filter(TextFieldsTable.name == inproperFieldName).update(TextFieldsTable.isMultiline <- true))
        }
        
        // Repair legacy Description fields to use multiline
        try db.run(TextFieldsTable.table.filter(TextFieldsTable.name == "Description").filter(TextFieldsTable.isMultiline == false).update(TextFieldsTable.isMultiline <- true))
        
        // Repair legacy Comments fields to use multiline
        try db.run(TextFieldsTable.table.filter(TextFieldsTable.name == "Comments").filter(TextFieldsTable.isMultiline == false).update(TextFieldsTable.isMultiline <- true))
        
        // Add default field templates
        let textFieldTemp = "INSERT INTO text_field_templates (is_multiline, id, name)"
        
        try db.run("\(textFieldTemp) VALUES(0, 1, 'Title');")
        try db.run("\(textFieldTemp) VALUES(0, 2, 'Author');")
        try db.run("\(textFieldTemp) VALUES(0, 3, 'Artist');")
        try db.run("\(textFieldTemp) VALUES(0, 4, 'URL');")
        try db.run("\(textFieldTemp) VALUES(1, 5, 'Description');")
        try db.run("\(textFieldTemp) VALUES(1, 6, 'Notes');")
        try db.run("\(textFieldTemp) VALUES(1, 7, 'Comments');")
        
        try db.run("INSERT INTO datetime_field_templates (id, name) VALUES(1, 'Date');")
        
        // Add indices for preformance
        try db.execute("CREATE INDEX IF NOT EXISTS idx_tags_name_shorthand ON tags (name, shorthand)")
        try db.execute("CREATE INDEX IF NOT EXISTS idx_tag_parents_child_id ON tag_parents (child_id)")
        try db.execute("CREATE INDEX IF NOT EXISTS idx_tag_entries_entry_id ON tag_entries (entry_id)")
    }
    
    /// Migrate to database version 201
    private func migrateDB201(db: Connection) throws {
        try db.execute("""
        CREATE TABLE text_fields_new (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            name VARCHAR NOT NULL,
            entry_id INTEGER NOT NULL,
            value VARCHAR,
            is_multiline BOOLEAN NOT NULL,
            FOREIGN KEY(entry_id) REFERENCES entries (id)
        );
        CREATE TABLE datetime_fields_new (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            name VARCHAR NOT NULL,
            entry_id INTEGER NOT NULL,
            value VARCHAR,
            FOREIGN KEY(entry_id) REFERENCES entries (id)
        );
        """)
            
        try db.execute("""
        INSERT INTO text_fields_new (id, name, entry_id, value, is_multiline)
        SELECT id, name, entry_id, value, is_multiline
        FROM text_fields
        """)
            
        try db.execute("DROP TABLE text_fields")
        try db.execute("ALTER TABLE text_fields_new RENAME TO text_fields")
            
        try db.execute("""
        INSERT INTO datetime_fields_new (id, name, entry_id, value)
        SELECT id, name, entry_id, value
        FROM datetime_fields
        """)
            
        try db.execute("DROP TABLE datetime_fields")
        try db.execute("ALTER TABLE datetime_fields_new RENAME TO datetime_fields")
    }
    
    /// Migrate to database version 202
    private func migrateDB202(db: Connection) throws {
        // Delete TagParents with no existing child
        try removeTagParentsOrphans(TagParentsTable.childId, db: db)
    }
    
    /// Migrate to database version 300
    private func migrateDB300(db: Connection) throws {
        // Remove folder_id
        try db.execute("""
           CREATE TABLE entries_new (
               id INTEGER NOT NULL,
               path VARCHAR NOT NULL,
               suffix VARCHAR NOT NULL,
               date_created DATETIME,
               date_modified DATETIME,
               date_added DATETIME,
               filename TEXT NOT NULL DEFAULT '',
               PRIMARY KEY (id),
               UNIQUE (path)
           )
        """)
        
        // Transfer data into new table
        try db.execute("""
            INSERT INTO entries_new (id, path, suffix, date_created, date_modified, date_added, filename)
            SELECT id, path, suffix, date_created, date_modified, date_added, filename
            FROM entries
        """)
        
        // Delete old table and rename new table in place
        try db.execute("DROP TABLE entries")
        try db.execute("ALTER TABLE entries_new RENAME TO entries")
        
        // Delete unused folders table
        try db.execute("DROP TABLE folders")
    }
}

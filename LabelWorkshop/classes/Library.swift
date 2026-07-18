import Foundation
import UIKit
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
            if let row = try? self.pluck(VersionTable.table.filter(VersionTable.key == "CURRENT")) {
                return row[VersionTable.value]
            }
            return 0
        }
        set { try? self.run(VersionTable.table.filter(VersionTable.key == "CURRENT")
            .update(VersionTable.value <- Int(newValue)))
        }
    }
}

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

class Library: Hashable, Identifiable, ObservableObject {
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
    var migrationState: MigrationState = .Unknown
    var migrationDebug: MigrationDebug = .Default
    var isNew: Bool
    @Published var migrationPercentage = 0.0
    
    var tags: LibraryTagManager!
    
    var thumbnailCache: EntryThumbnailCache = EntryThumbnailCache()
    
    init(bookmarkKey: String) {
        self.bookmarkKey = bookmarkKey
        self.bookmark = loadBookmark(key: self.bookmarkKey)
        self.isNew = false
        do {
            // Create TagStudio folder if not already created
            if let bookmark = bookmark {
                print(bookmark.appendingPathComponent(".TagStudio"))
                try FileManager.default.createDirectory(
                    at: bookmark.appendingPathComponent(".TagStudio"),
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                self.isNew = !FileManager.default.fileExists(atPath: bookmark.appendingPathComponent(".TagStudio/ts_library.sqlite").path)
            }
            // Inititalize Database
            let dbFile = self.bookmark?.appendingPathComponent(".TagStudio/ts_library.sqlite").absoluteString ?? ""
            self.db = try Connection(dbFile)
            // Get Field Types
            for rawFieldType in try self.db!.prepare(TextFieldTemplatesTable.table) {
                self.fieldTypes.append(
                    FieldType(
                        id: rawFieldType[TextFieldTemplatesTable.id],
                        name: rawFieldType[TextFieldTemplatesTable.name]
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
        if let bookmark = self.bookmark {
            self.matcher = TSIgnoreMatcher(contents: ignoreList, baseURL: bookmark)
        }
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
            for rawEntry in try self.db!.prepare(EntriesTable.table.limit(limit)) {
                let path: String = rawEntry[EntriesTable.path]
                let id: Int = rawEntry[EntriesTable.id]
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
        let sequenceQuery = SequenceTable.table.filter(SequenceTable.name == "tags")
        do {
            if let raw = try self.db?.pluck(sequenceQuery) {
                let sequence = raw[SequenceTable.sequence]
                if let sequence = sequence {
                    let query = TagsTable.table.insert(
                        TagsTable.name <- name,
                        TagsTable.isCategory <- false,
                        TagsTable.isHidden <- false
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
    
    func backupDB() async throws {
        let backupPath = self.bookmark?.appendingPathComponent(".TagStudio/ts_library.sqlite.bak")
        let backupDB = try Connection(backupPath?.path ?? "")
        let backup = try self.db?.backup(usingConnection: backupDB)
        try backup?.step()
    }
    
    func migrate() async throws {
        print("Starting migration for \"\(self.getName())\"")
        
        try await self.backupDB()
        
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
            Migration(version: 202, legacyVersioning: false, run: migrateDB202)
        ]
        var requiedMigrations: [Migration] = []
        
        var databaseVersion: Int = 0
        
        if !self.isNew && self.db?.legacyDatabaseVersion ?? 0 < 8 {
            throw LibraryError.databaseUnmigrateable
        }
        
        if self.db?.databaseVersion == 0 {
            databaseVersion = self.db?.legacyDatabaseVersion ?? 0
        } else {
            databaseVersion = self.db?.databaseVersion ?? 0
        }
        
        print("DB Version: \(databaseVersion)")
        
        if !self.isNew && databaseVersion == 0 {throw LibraryError.databaseUnmigrateable}
        
        for migration in migrations {
            if !(databaseVersion >= migration.version) {
                requiedMigrations.append(migration)
            }
        }
        if requiedMigrations.isEmpty {
            self.migrationState = .MigrationNotRequired
            return
        } else {
            self.migrationState = .MigrationInProgress
        }
            
        var i = 1
        for migration in requiedMigrations {
            if self.migrationDebug == .Delay {
                try await Task.sleep(for: .seconds(2))
            }
            do {
                if self.migrationDebug == .Crash {
                    throw LibraryError.databaseUnmigrateable
                }
                try self.db?.transaction {
                    try migration.run()
                    if migration.legacyVersioning {
                        self.db?.legacyDatabaseVersion = migration.version
                    } else {
                        self.db?.databaseVersion = migration.version
                    }
                }
                print("Migrated to version \(migration.version)")
            } catch {
                print("Migration to version \(migration.version) failed")
                self.migrationState = .MigrationFailed
                throw error
            }
            await MainActor.run { [i, requiedMigrations] in
                self.migrationPercentage = Double(i) / Double(requiedMigrations.count) * 100
            }
            i+=1
        }
        if migrationState == .MigrationFailed {return}
        await MainActor.run {
            self.migrationState = .MigrationComplete
            self.migrationPercentage = 100
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
            try self.db?.run(execution)
        }
    }
    
    /// Migrate to database version 9
    private func migrateDB9() throws {
        // Add filename column to entries table
        try self.db?.execute("ALTER TABLE entries ADD COLUMN filename TEXT NOT NULL DEFAULT ''")
        
        // Populate filename column
        try self.safeGetEntries().forEach { entry in
            let sqlEntry = EntriesTable.table.filter(EntriesTable.id == entry.id)
            try self.db?.run(sqlEntry.update(EntriesTable.filename <- entry.fullPath?.lastPathComponent ?? ""))
        }
    }
    
    /// Migrate to database version 100
    private func migrateDB100() throws {
        guard let tagParentsStmt = try self.db?.prepare(TagParentsTable.table.select(*)) else {
            throw LibraryError.databaseUnmigrateable
        }
        let tagParents = Array(tagParentsStmt)
        
        for tagParent in tagParents {
            try self.db?.run(TagParentsTable.table
                .select(*)
                .filter(TagParentsTable.childId == tagParent[TagParentsTable.childId])
                .filter(TagParentsTable.parentId == tagParent[TagParentsTable.parentId])
                .update(TagParentsTable.childId <- tagParent[TagParentsTable.parentId],
                        TagParentsTable.parentId <- tagParent[TagParentsTable.childId]))
        }
    }
    
    /// Migrate to database version 101
    private func migrateDB101() throws {
        let createVersions = VersionTable.table.create { table in
            table.column(VersionTable.key, primaryKey: true)
            table.column(VersionTable.value, defaultValue: 0)
        }
        let insertVersion = VersionTable.table.insert(VersionTable.key <- "CURRENT", VersionTable.value <- 101)
        try self.db?.run(createVersions)
        try self.db?.run(insertVersion)
    }
    
    /// Migrate to database version 102
    private func migrateDB102() throws {
        // Delete TagParents with no existing parent
        try removeTagParentsOrphans(TagParentsTable.parentId)
    }
    
    private func removeTagParentsOrphans(_ expression: SQLite.Expression<Int>) throws {
        let tagParents = try self.db?.prepare(TagParentsTable.table.select(TagParentsTable.parentId, TagParentsTable.childId))
        
        let validTagIds = try db?.prepare(
            TagsTable.table.select(TagsTable.id)
        ).map { $0[TagsTable.id] }
        
        guard let validTagIds, let tagParents else { throw LibraryError.databaseUnmigrateable }
        
        
        let tagParentRows = Array(tagParents)
        
        for tagParent in tagParentRows {
            let isInvalid = validTagIds.filter { tagId in
                tagId == tagParent[expression]
            }.isEmpty
            
            if isInvalid {
                try self.db?.run(
                    TagParentsTable.table
                        .filter(TagParentsTable.childId == tagParent[TagParentsTable.childId])
                        .filter(TagParentsTable.parentId == tagParent[TagParentsTable.parentId])
                        .delete()
                )
            }
        }
    }
    
    /// Migrate to database version 103
    private func migrateDB103() throws {
        try self.db?.execute("ALTER TABLE tags ADD COLUMN is_hidden BOOLEAN NOT NULL DEFAULT 0")
        try self.db?.run(TagsTable.table.filter(TagsTable.id == 0).update(TagsTable.isHidden <- true))
    }
    
    /// Migrate to database version 104
    private func migrateDB104() throws {
        let isExcludeRow = try self.db?.prepare("SELECT value FROM preferences WHERE key = 'IS_EXCLUDE_LIST'").makeIterator().next()
        let isExcludeValue = isExcludeRow?[0] as? String
        
        var extensionsValue = "[]"
        if let extensionsRow = try self.db?.prepare("SELECT value FROM preferences WHERE key = 'EXTENSION_LIST'") {
            for row in extensionsRow {
                extensionsValue = row[0] as? String ?? "[]"
            }
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
        
        if let ignoreFile = self.bookmark?.appendingPathComponent(".TagStudio/.ts_ignore") {
            try output.write(to: ignoreFile, atomically: true, encoding: .utf8)
        }
        
        try self.db?.execute("DROP TABLE preferences")
    }
    
    /// Migrate to database version 200 UNCOMPLETE
    private func migrateDB200() throws {
        try self.db?.execute("""
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
        try self.db?.execute("DROP TABLE IF EXISTS boolean_fields")
        try self.db?.execute("DROP TABLE IF EXISTS value_type")
        
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
        let textFields = try self.db?.prepare(TextFieldsTable.table)
        for textField in textFields! {
            try self.db?.run(TextFieldsTable.table.update(TextFieldsTable.name <- textField[TextFieldsTable.name].capitalized.replacingOccurrences(of: "Url", with: "URL")))
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
            try self.db?.run(TextFieldsTable.table.select(TextFieldsTable.name == inproperFieldName).update(TextFieldsTable.isMultiline <- true))
        }
        
        // Repair legacy Description fields to use multiline
        try self.db?.run(TextFieldsTable.table.select(TextFieldsTable.name == "Description").select(TextFieldsTable.isMultiline == false).update(TextFieldsTable.isMultiline <- true))
        
        // Repair legacy Comments fields to use multiline
        try self.db?.run(TextFieldsTable.table.select(TextFieldsTable.name == "Comments").select(TextFieldsTable.isMultiline == false).update(TextFieldsTable.isMultiline <- true))
        
        // Add default field templates
        let textFieldTemp = "INSERT INTO text_field_templates (is_multiline, id, name)"
        
        try self.db?.run("\(textFieldTemp) VALUES(0, 1, 'Title');")
        try self.db?.run("\(textFieldTemp) VALUES(0, 2, 'Author');")
        try self.db?.run("\(textFieldTemp) VALUES(0, 3, 'Artist');")
        try self.db?.run("\(textFieldTemp) VALUES(0, 4, 'URL');")
        try self.db?.run("\(textFieldTemp) VALUES(1, 5, 'Description');")
        try self.db?.run("\(textFieldTemp) VALUES(1, 6, 'Notes');")
        try self.db?.run("\(textFieldTemp) VALUES(1, 7, 'Comments');")
        
        try self.db?.run("INSERT INTO datetime_field_templates (id, name) VALUES(1, 'Date');")
        
        // Add indices for preformance
        try self.db?.execute("CREATE INDEX IF NOT EXISTS idx_tags_name_shorthand ON tags (name, shorthand)")
        try self.db?.execute("CREATE INDEX IF NOT EXISTS idx_tag_parents_child_id ON tag_parents (child_id)")
        try self.db?.execute("CREATE INDEX IF NOT EXISTS idx_tag_entries_entry_id ON tag_entries (entry_id)")
    }
    
    private func migrateDB201() throws {
        try self.db?.execute("""
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
            
        try self.db?.execute("""
        INSERT INTO text_fields_new (id, name, entry_id, value, is_multiline)
        SELECT id, name, entry_id, value, is_multiline
        FROM text_fields
        """)
            
        try self.db?.execute("DROP TABLE text_fields")
        try self.db?.execute("ALTER TABLE text_fields_new RENAME TO text_fields")
            
        try self.db?.execute("""
        INSERT INTO datetime_fields_new (id, name, entry_id, value)
        SELECT id, name, entry_id, value
        FROM datetime_fields
        """)
            
        try self.db?.execute("DROP TABLE datetime_fields")
        try self.db?.execute("ALTER TABLE datetime_fields_new RENAME TO datetime_fields")
    }
    
    private func migrateDB202() throws {
        // Delete TagParents with no existing child
        try removeTagParentsOrphans(TagParentsTable.childId)
    }
}


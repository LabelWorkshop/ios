import SwiftUI
import UniformTypeIdentifiers
import Foundation
import SQLite

@Observable
class Entry {
    var path: String
    var id: Int
    var fullPath: URL?
    var tags: EntryTagManager?
    var fields: EntryFieldManager?
    let library: Library
    var type: ExtensionTypes = .Unknown
    
    init (library: Library, path: String, id: Int) {
        self.path = path
        self.library = library
        self.id = id
        if library.bookmark != nil { self.fullPath = library.bookmark?.appendingPathComponent(path) }
        
        // Get Ext Type
        let ext = path.split(separator: ".").last?.lowercased() ?? ""
        let type = UTType(filenameExtension: ext)
        if type?.conforms(to: .gif) ?? false {
            self.type = .AnimatedImage
        }
        if type?.conforms(to: .movie) ?? false {
            self.type = .Video
        }
        if type?.conforms(to: .image) ?? false || ext == "pxd" {
            self.type = .Image
        }
        if type?.conforms(to: .audio) ?? false {
            self.type = .Audio
        }
        if type?.conforms(to: .archive) ?? false {
            self.type = .Archive
        }
        if ["txt",
            "json",
            "md",
            "plist",
            "strings",
            "yml",
            "yaml",
            "toml",
            "ini",
            "gitignore",
            "gitattributes",
            "log"
        ].contains(ext) {
            self.type = .PlainText
        }
        
        do {
            self.tags = try EntryTagManager(self)
            self.fields = try EntryFieldManager(self)
        } catch {print(error)}
    }
    
    @available(*, deprecated, message: "Use EntryManager.delete instead.")
    func delete() {
        let queries = [
            DateFieldsTable.table
                .filter(EntriesTable.id == self.id)
                .delete(),
            TextFieldsTable.table
                .filter(EntriesTable.id == self.id)
                .delete(),
            TagEntriesTable.table
                .filter(EntriesTable.id == self.id)
                .delete(),
            EntriesTable.table
                .filter(EntriesTable.id == self.id)
                .delete()
        ]
        do {
            for query in queries {
                try self.library.db!.run(query)
            }
        } catch {print(error)}
    }
    
    func withScopedURL<T>(
        _ body: (URL) throws -> T?
    ) rethrows -> T? {
        guard let url = self.fullPath,
              let bookmark = self.library.bookmark,
              bookmark.startAccessingSecurityScopedResource()
        else {
            return nil
        }

        defer {
            bookmark.stopAccessingSecurityScopedResource()
        }

        return try body(url)
    }
}

import SwiftUI
import SQLite

@Observable
class TagColorManager {
    var colors: [TagColor] = [TagColor.none]
    let library: Library
    var namespaces: [TagColorNamespace] = []
    
    init(library: Library) {
        self.library = library
        let query = TagColorsTable.table.select(
            TagColorsTable.primary,
            TagColorsTable.secondary,
            TagColorsTable.slug,
            TagColorsTable.namespace,
            TagColorsTable.name
        )
        do {
            for rawColor in try library.db!.prepare(query) {
                let namespace = rawColor[TagColorsTable.namespace]
                let slug = rawColor[TagColorsTable.slug]
                self.colors.append(
                    TagColor(
                        namespace: namespace,
                        slug: slug,
                        primaryColor: rawColor[TagColorsTable.primary],
                        secondaryColor: rawColor[TagColorsTable.secondary]
                    )
                )
            }
            
            try refreshNamespaces()
        } catch {print(error)}
    }
    
    func refreshNamespaces() throws {
        let namespacesRows = try self.library.db?.prepare(
            NamespacesTable.table.select(*)
        )
        
        var newNamespaces: [TagColorNamespace] = []
        
        if let namespacesRows {
            let namespacesArray = Array(namespacesRows)
            for namespace in namespacesArray {
                newNamespaces.append(TagColorNamespace(
                    namespace: namespace[NamespacesTable.namespace],
                    name: namespace[NamespacesTable.name],
                    manager: self
                ))
            }
        }
        
        namespaces = newNamespaces
    }
    
    func find(namespace: String, slug: String) -> TagColor? {
        var color: TagColor? = nil
        self.colors.forEach { clr in
            if clr.namespace == namespace && clr.slug == slug {
                color = clr
            }
        }
        return color
    }
    
    func newNamespace(name: String, namespace: String) throws {
        try self.library.db?.run(
            NamespacesTable.table.insert(
                NamespacesTable.name <- name,
                NamespacesTable.namespace <- namespace
            )
        )
        try self.refreshNamespaces()
    }
    
    func deleteNamespace(namespace: String) throws {
        try self.library.db?.run(
            NamespacesTable.table.filter(
                NamespacesTable.namespace == namespace
            ).delete()
        )
        try self.refreshNamespaces()
    }
    
    func deleteNamespace(namespace: TagColorNamespace) throws {
        try deleteNamespace(namespace: namespace.namespace)
    }
}

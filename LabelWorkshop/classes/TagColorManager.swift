import SQLite

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
            
            let namespacesRows = try self.library.db?.prepare(
                NamespacesTable.table.select(*)
            )
            
            if let namespacesRows {
                let namespacesArray = Array(namespacesRows)
                for namespace in namespacesArray {
                    namespaces.append(TagColorNamespace(namespace: namespace[NamespacesTable.namespace], manager: self))
                }
            }
            
            
        } catch {print(error)}
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
    }
}

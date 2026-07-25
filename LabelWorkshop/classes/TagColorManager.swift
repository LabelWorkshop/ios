import SwiftUI
import SQLite

enum TagColorError: Error {
    case hexConversionError
    case updateError
}

@Observable
class TagColorManager {
    var colors: [TagColor] = [TagColor.none]
    let library: Library
    var namespaces: [TagColorNamespace] = []
    
    init(library: Library) {
        self.library = library
        do {
            try refreshColors()
            try refreshNamespaces()
        } catch {print(error)}
    }
    
    func refreshColors() throws {
        let query = TagColorsTable.table.select(
            TagColorsTable.primary,
            TagColorsTable.secondary,
            TagColorsTable.slug,
            TagColorsTable.namespace,
            TagColorsTable.name,
            TagColorsTable.colorBorder
        )
        
        var updatedColors = [TagColor.none]
        
        for rawColor in try library.db!.prepare(query) {
            let namespace = rawColor[TagColorsTable.namespace]
            let slug = rawColor[TagColorsTable.slug]
            updatedColors.append(
                TagColor(
                    namespace: namespace,
                    slug: slug,
                    primaryColor: rawColor[TagColorsTable.primary],
                    secondaryColor: rawColor[TagColorsTable.secondary],
                    name: rawColor[TagColorsTable.name],
                    useSecondaryBorder: rawColor[TagColorsTable.colorBorder]
                )
            )
        }
        
        self.colors = updatedColors
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
    
    func renameNamespace(namespace: String, to name: String) throws {
        try self.library.db?.run(
            NamespacesTable.table.filter(
                NamespacesTable.namespace == namespace
            )
            .update(
                NamespacesTable.name <- name
            )
        )
        try self.refreshNamespaces()
    }
    
    func renameNamespace(namespace: TagColorNamespace, to name: String) throws {
        try renameNamespace(namespace: namespace.namespace, to: name)
    }
    
    func newColor(
        namespace: String,
        primary: Color,
        secondary: Color,
        name: String,
        slug: String,
        secondaryAsBorder: Bool
    ) throws -> TagColor {
        guard let primaryHex = primary.toHex(),
              let secondaryHex = secondary.toHex() else {
            throw TagColorError.hexConversionError
        }
        
        try self.library.db?.run(
            TagColorsTable.table.insert(
                TagColorsTable.namespace <- namespace,
                TagColorsTable.primary <- primaryHex,
                TagColorsTable.secondary <- secondaryHex,
                TagColorsTable.name <- name,
                TagColorsTable.slug <- slug,
                TagColorsTable.colorBorder <- secondaryAsBorder
            )
        )
        
        let created = TagColor(
            namespace: namespace,
            slug: slug,
            primaryColor: primaryHex,
            secondaryColor: secondaryHex,
            name: name,
            useSecondaryBorder: secondaryAsBorder
        )
        self.colors.append(created)
        return created
    }
    
    func newColor(
        namespace: TagColorNamespace,
        primary: Color,
        secondary: Color,
        name: String,
        slug: String,
        secondaryAsBorder: Bool
    ) throws -> TagColor {
        try self.newColor(
            namespace: namespace.namespace,
            primary: primary,
            secondary: secondary,
            name: name,
            slug: slug,
            secondaryAsBorder: secondaryAsBorder
        )
    }
    
    func updateColor(
        oldSlug: String,
        primary: Color,
        secondary: Color,
        name: String,
        slug: String,
        secondaryAsBorder: Bool
    ) throws {
        try self.library.db?.run(
            TagColorsTable.table.filter(
                TagColorsTable.slug == oldSlug
            ).update(
                TagColorsTable.primary <- primary.toHex() ?? "",
                TagColorsTable.secondary <- secondary.toHex() ?? "",
                TagColorsTable.name <- name,
                TagColorsTable.slug <- slug,
                TagColorsTable.colorBorder <- secondaryAsBorder
            )
        )
        
        try self.refreshColors()
    }
    
    func updateColor(
        color: TagColor,
        primary: Color,
        secondary: Color,
        name: String,
        slug: String,
        secondaryAsBorder: Bool
    ) throws {
        try self.updateColor(oldSlug: color.slug, primary: primary, secondary: secondary, name: name, slug: slug, secondaryAsBorder: secondaryAsBorder)
    }
}

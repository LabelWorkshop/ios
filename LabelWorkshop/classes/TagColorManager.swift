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
        } catch {print(error)}
        
        for color in colors {
            if !namespaces.contains(where: { $0.namespace == color.namespace }) && color.namespace != "none" {
                namespaces.append(
                    TagColorNamespace(namespace: color.namespace, manager: self)
                )
            }
        }
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
}

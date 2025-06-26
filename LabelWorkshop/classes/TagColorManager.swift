class TagColorManager {
    var colors: [TagColor] = [TagColor.none]
    let library: Library
    
    init(library: Library) {
        self.library = library
        let query = TagColor.tagColorsTable.select(
            TagColor.primaryColumn,
            TagColor.secondaryColumn,
            TagColor.slugColumn,
            TagColor.namespaceColumn,
            TagColor.nameColumn
        )
        do {
            for rawColor in try library.db!.prepare(query) {
                let namespace = rawColor[TagColor.namespaceColumn]
                let slug = rawColor[TagColor.slugColumn]
                self.colors.append(
                    TagColor(
                        namespace: namespace,
                        slug: slug,
                        primaryColor: rawColor[TagColor.primaryColumn],
                        secondaryColor: rawColor[TagColor.secondaryColumn]
                    )
                )
            }
        } catch {}
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

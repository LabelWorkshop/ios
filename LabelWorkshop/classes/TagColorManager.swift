class TagColorManager {
    var colors: [TagColor] = []
    let library: Library
    
    init(library: Library) {
        self.library = library
        let query = TagColor.tagColorsTable.select(
            TagColor.primaryColumn,
            TagColor.secondaryColumn,
            TagColor.slugColumn,
            TagColor.namespaceColumn
        )
        do {
            for rawColor in try library.db!.prepare(query) {
                self.colors.append(
                    TagColor(
                        namespace: rawColor[TagColor.namespaceColumn],
                        slug: rawColor[TagColor.slugColumn],
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

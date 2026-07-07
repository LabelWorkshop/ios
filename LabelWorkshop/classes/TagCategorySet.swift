class TagCategorySet {
    let parent: Tag
    var children: [Tag]
    
    init(parent: Tag, children: [Tag]) {
        self.parent = parent
        self.children = children
    }
}

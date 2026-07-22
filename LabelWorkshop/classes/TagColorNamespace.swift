class TagColorNamespace: Identifiable {
    let manager: TagColorManager
    let namespace: String
    
    var colors: [TagColor] {
        manager.colors.filter{ $0.namespace == namespace }
    }
    
    init(namespace: String, manager: TagColorManager) {
        self.manager = manager
        self.namespace = namespace
    }
}

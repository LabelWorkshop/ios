import SwiftUI

class TagColorNamespace: Identifiable {
    let manager: TagColorManager
    let namespace: String
    let name: String
    
    var colors: [TagColor] {
        manager.colors.filter{ $0.namespace == namespace }
    }
    
    var isReadOnly: Bool {
        namespace.starts(with: "tagstudio")
    }
    
    var displayName: String {
        if isReadOnly {
            NSLocalizedString(
                "colors.\(namespace)",
                comment: ""
            )
        } else {
            name
        }
    }
    
    init(namespace: String, name: String, manager: TagColorManager) {
        self.manager = manager
        self.namespace = namespace
        self.name = name
    }
}

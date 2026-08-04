import SQLite
import SwiftUI

struct TagAlias: Identifiable {
    
    
    var id: Int
    var name: String
    var tagId: Int
    var tag: Tag?
    
    init(id: Int, name: String, tagId: Int, tag: Tag? = nil) {
        self.id = id
        self.name = name
        self.tagId = tagId
        self.tag = tag
    }
    
    mutating func setName(_ name: String) {
        do {
            let query = TagAliasesTable.table
                .select(*)
                .filter(TagAliasesTable.id == self.id)
                .update(TagAliasesTable.name <- name)
            try tag?.library?.db?.run(query)
            self.name = name
        } catch {print(error)}
    }
    
    func delete() {
        do {
            let query = TagAliasesTable.table
                .select(*)
                .filter(TagAliasesTable.id == id)
                .delete()
            try tag?.library?.db?.run(query)
        } catch {print(error)}
    }
}

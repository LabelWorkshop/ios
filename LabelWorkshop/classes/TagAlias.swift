import SQLite
import SwiftUI

struct TagAlias: Identifiable {
    static let tagAliasesTable = Table("tag_aliases")
    static let nameColumn = Expression<String>("name")
    static let tagIdColumn = Expression<Int>("tag_id")
    static let idColumn = Expression<Int>("id")
    
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
            let query = TagAlias.tagAliasesTable
                .select(*)
                .filter(TagAlias.idColumn == self.id)
                .update(TagAlias.nameColumn <- name)
            try tag?.library.db?.run(query)
            self.name = name
        } catch {}
    }
    
    func delete() {
        do {
            let query = TagAlias.tagAliasesTable
                .select(*)
                .filter(TagAlias.idColumn == id)
                .delete()
            try tag?.library.db?.run(query)
        } catch {}
    }
}

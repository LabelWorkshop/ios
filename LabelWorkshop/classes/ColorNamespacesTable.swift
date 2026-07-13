import SQLite

struct ColorNamespacesTable {
    static let table = Table("namespaces")
    static let namespace = Expression<String>("namespace")
    static let name = Expression<String>("name")
}

struct Migration {
    let version: Int
    let legacyVersioning: Bool
    let run: () throws -> Void
}

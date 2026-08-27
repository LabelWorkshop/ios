import Foundation

@Observable
class LibraryManager {
    var libraries: [Library] = []
    
    init() {
        let rawLibraries: [String] = getRaw()
        for rawLibrary in rawLibraries {
            insert(rawLibrary)
        }
    }
    
    func insert(_ bookmarkKey: String) {
        if let lib = Library.fetch(bookmarkKey: bookmarkKey) {
            libraries.append(lib)
        }
    }
    
    private func getRaw() -> [String] {
        return UserDefaults.standard.object(forKey: "libraries") as? [String] ?? [String]()
    }
    
    private func setRaw(_ rawLibraries: [String]) {
        UserDefaults.standard.set(rawLibraries, forKey: "libraries")
    }
    
    func remove(at indexSet: IndexSet){
        var rawLibraries = getRaw()
        for index in indexSet {
            rawLibraries.remove(at: index)
            libraries.remove(at: index)
        }
        setRaw(rawLibraries)
    }
    
    func add(key: String) {
        var rawLibraries = getRaw()
        rawLibraries.append(key)
        setRaw(rawLibraries)
        insert(key)
    }
    
    func clear() {
        libraries.removeAll()
        setRaw([])
    }
}

import XCTest
import SQLite
@testable import LabelWorkshop

final class LibraryTagManagerTests: XCTestCase {
    private var database: Connection!
    private var library: Library!

    override func setUp() async throws {
        database = try Connection(.inMemory)
        
        library = Library(
            bookmarkKey: "test-library",
            bookmark: URL(fileURLWithPath: NSTemporaryDirectory()),
            db: database
        )
        
        try await library.migrator?.migrate()
    }

    func testCreatesAndUpdatesTag() throws {
        let tag = try XCTUnwrap(library.tags.new("Music"))

        try library.tags.updateTag(
            tag,
            options: TagOptions(
                name: "Audio",
                shorthand: "aud",
                isCategory: true,
                isHidden: true,
                disambiguationId: nil,
                aliases: nil,
                color: nil,
                parents: nil
            )
        )

        library.tags.refresh()
        let saved = try XCTUnwrap(library.tags.getById(id: tag.id))
        XCTAssertEqual(saved.name, "Audio")
        XCTAssertEqual(saved.shorthand, "aud")
        XCTAssertEqual(saved.isCategory, true)
        XCTAssertEqual(saved.isHidden, true)
    }
}


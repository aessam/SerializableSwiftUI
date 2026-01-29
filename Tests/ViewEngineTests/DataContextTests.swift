import XCTest
@testable import ViewEngine

final class DataContextTests: XCTestCase {
    func testSimpleResolve() {
        let ctx = DataContext(data: ["name": .string("Test")])
        XCTAssertEqual(ctx.resolve("$.name")?.stringValue, "Test")
    }

    func testNestedResolve() {
        let ctx = DataContext(data: [
            "podcast": .dictionary(["trackName": .string("My Podcast"), "trackId": .int(123)])
        ])
        XCTAssertEqual(ctx.resolve("$.podcast.trackName")?.stringValue, "My Podcast")
        XCTAssertEqual(ctx.resolve("$.podcast.trackId")?.intValue, 123)
    }

    func testParentContext() {
        let parent = DataContext(data: ["global": .string("value")])
        let child = parent.child(with: ["local": .string("child_value")])
        XCTAssertEqual(child.resolve("$.local")?.stringValue, "child_value")
        XCTAssertEqual(child.resolve("$.global")?.stringValue, "value")
    }

    func testChildOverridesParent() {
        let parent = DataContext(data: ["key": .string("parent")])
        let child = parent.child(with: ["key": .string("child")])
        XCTAssertEqual(child.resolve("$.key")?.stringValue, "child")
    }

    func testResolveString() {
        let ctx = DataContext(data: ["name": .string("Hello")])
        XCTAssertEqual(ctx.resolveString("$.name"), "Hello")
        XCTAssertEqual(ctx.resolveString("literal"), "literal")
        XCTAssertEqual(ctx.resolveString("\\$escaped"), "$escaped")
    }

    func testResolveWithTransform() {
        let ctx = DataContext(data: ["name": .string("hello")])
        XCTAssertEqual(ctx.resolve("$.name | uppercase")?.stringValue, "HELLO")
    }

    func testResolveNilPath() {
        let ctx = DataContext(data: [:])
        XCTAssertNil(ctx.resolve("$.nonexistent"))
    }

    func testArrayAccess() {
        let ctx = DataContext(data: [
            "items": .array([.string("a"), .string("b"), .string("c")])
        ])
        XCTAssertEqual(ctx.resolve("$.items.1")?.stringValue, "b")
    }
}

import XCTest
@testable import ViewEngine

final class ViewNodeDecodingTests: XCTestCase {
    func testDecodeSimpleText() throws {
        let json = """
        {"type":"text","props":{"content":"Hello"}}
        """
        let node = try JSONDecoder().decode(ViewNode.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(node.type, "text")
        XCTAssertEqual(node.stringProp("content"), "Hello")
    }

    func testDecodeVStackWithChildren() throws {
        let json = """
        {"type":"vstack","props":{"spacing":8},"children":[{"type":"text","props":{"content":"A"}},{"type":"text","props":{"content":"B"}}]}
        """
        let node = try JSONDecoder().decode(ViewNode.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(node.type, "vstack")
        XCTAssertEqual(node.doubleProp("spacing"), 8)
        XCTAssertEqual(node.children?.count, 2)
    }

    func testDecodeWithCondition() throws {
        let json = """
        {"type":"text","condition":"$.visible == true","props":{"content":"Hi"}}
        """
        let node = try JSONDecoder().decode(ViewNode.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(node.condition, "$.visible == true")
    }

    func testDecodeActionDefinition() throws {
        let json = """
        {"type":"button","props":{"action":{"actionType":"navigate","screen":"detail","params":{"id":"$.item.trackId"}}}}
        """
        let node = try JSONDecoder().decode(ViewNode.self, from: json.data(using: .utf8)!)
        let action = node.actionProp("action")
        XCTAssertEqual(action?.actionType, "navigate")
        XCTAssertEqual(action?.screen, "detail")
    }

    func testDecodeTabDefinitions() throws {
        let json = """
        {"type":"tab_view","props":{"tabs":[{"title":"Browse","icon":"square.grid.2x2","screen":"browse"}]}}
        """
        let node = try JSONDecoder().decode(ViewNode.self, from: json.data(using: .utf8)!)
        let tabs = node.tabsProp()
        XCTAssertEqual(tabs?.count, 1)
        XCTAssertEqual(tabs?.first?.title, "Browse")
    }

    func testAnyCodableValueRoundTrip() throws {
        let original = AnyCodableValue.dictionary([
            "name": .string("test"),
            "count": .int(42),
            "active": .bool(true),
            "items": .array([.string("a"), .string("b")])
        ])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AnyCodableValue.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    func testComponentDefinitionDecoding() throws {
        let json = """
        {"parameters":["podcast"],"body":{"type":"text","props":{"content":"$.podcast.name"}}}
        """
        let comp = try JSONDecoder().decode(ComponentDefinition.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(comp.parameters, ["podcast"])
        XCTAssertEqual(comp.body.type, "text")
    }
}

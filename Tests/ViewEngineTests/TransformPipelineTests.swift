import XCTest
@testable import ViewEngine

final class TransformPipelineTests: XCTestCase {
    func testUppercase() {
        let result = TransformPipeline.apply("uppercase", to: .string("hello"))
        XCTAssertEqual(result?.stringValue, "HELLO")
    }

    func testLowercase() {
        let result = TransformPipeline.apply("lowercase", to: .string("HELLO"))
        XCTAssertEqual(result?.stringValue, "hello")
    }

    func testJoin() {
        let result = TransformPipeline.apply("join:, ", to: .array([.string("a"), .string("b"), .string("c")]))
        XCTAssertEqual(result?.stringValue, "a, b, c")
    }

    func testDefault() {
        let result = TransformPipeline.apply("default:N/A", to: nil)
        XCTAssertEqual(result?.stringValue, "N/A")
        let result2 = TransformPipeline.apply("default:N/A", to: .string("exists"))
        XCTAssertEqual(result2?.stringValue, "exists")
    }

    func testTruncate() {
        let result = TransformPipeline.apply("truncate:5", to: .string("Hello World"))
        XCTAssertEqual(result?.stringValue, "Hello…")
    }

    func testTruncateNoOp() {
        let result = TransformPipeline.apply("truncate:20", to: .string("Short"))
        XCTAssertEqual(result?.stringValue, "Short")
    }

    func testCount() {
        let result = TransformPipeline.apply("count", to: .array([.int(1), .int(2), .int(3)]))
        XCTAssertEqual(result?.intValue, 3)
    }

    func testDuration() {
        let result = TransformPipeline.apply("duration:mm:ss", to: .int(125000))
        XCTAssertEqual(result?.stringValue, "2:05")
    }

    func testDateTransform() {
        let result = TransformPipeline.apply("date:yyyy", to: .string("2024-01-15T00:00:00Z"))
        XCTAssertEqual(result?.stringValue, "2024")
    }
}

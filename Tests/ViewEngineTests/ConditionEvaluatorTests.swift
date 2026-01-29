import XCTest
@testable import ViewEngine

final class ConditionEvaluatorTests: XCTestCase {
    func testEqualityTrue() {
        let ctx = DataContext(data: ["status": .string("active")])
        XCTAssertTrue(ConditionEvaluator.evaluate("$.status == 'active'", context: ctx))
    }

    func testEqualityFalse() {
        let ctx = DataContext(data: ["status": .string("inactive")])
        XCTAssertFalse(ConditionEvaluator.evaluate("$.status == 'active'", context: ctx))
    }

    func testNotEqual() {
        let ctx = DataContext(data: ["status": .string("inactive")])
        XCTAssertTrue(ConditionEvaluator.evaluate("$.status != 'active'", context: ctx))
    }

    func testGreaterThan() {
        let ctx = DataContext(data: ["count": .int(150)])
        XCTAssertTrue(ConditionEvaluator.evaluate("$.count > 100", context: ctx))
        XCTAssertFalse(ConditionEvaluator.evaluate("$.count > 200", context: ctx))
    }

    func testLessThan() {
        let ctx = DataContext(data: ["count": .int(50)])
        XCTAssertTrue(ConditionEvaluator.evaluate("$.count < 100", context: ctx))
    }

    func testExists() {
        let ctx = DataContext(data: ["name": .string("test")])
        XCTAssertTrue(ConditionEvaluator.evaluate("$.name | exists", context: ctx))
        XCTAssertFalse(ConditionEvaluator.evaluate("$.missing | exists", context: ctx))
    }

    func testEmpty() {
        let ctx = DataContext(data: ["items": .array([]), "name": .string("test")])
        XCTAssertTrue(ConditionEvaluator.evaluate("$.items | empty", context: ctx))
        XCTAssertFalse(ConditionEvaluator.evaluate("$.name | empty", context: ctx))
    }

    func testNotEmpty() {
        let ctx = DataContext(data: ["items": .array([.int(1)])])
        XCTAssertTrue(ConditionEvaluator.evaluate("$.items | !empty", context: ctx))
    }

    func testTruthyBinding() {
        let ctx = DataContext(data: ["flag": .bool(true)])
        XCTAssertTrue(ConditionEvaluator.evaluate("$.flag", context: ctx))
    }

    func testNumericEquality() {
        let ctx = DataContext(data: ["count": .int(42)])
        XCTAssertTrue(ConditionEvaluator.evaluate("$.count == 42", context: ctx))
    }
}

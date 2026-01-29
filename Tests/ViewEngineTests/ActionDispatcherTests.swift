import XCTest
@testable import ViewEngine
@testable import ActionSystem
@testable import PodcastData

final class ActionDispatcherTests: XCTestCase {
    func testNavigateAction() async {
        let dispatcher = ActionDispatcher()
        let ctx = DataContext(data: ["id": .int(123)])
        var navigatedScreen: String?
        var navigatedParams: [String: AnyCodableValue]?

        dispatcher.onNavigate = { screen, params in
            navigatedScreen = screen
            navigatedParams = params
        }

        let action = ActionDefinition(actionType: "navigate", screen: "detail",
                                       params: ["podcastId": .string("$.id")])
        await dispatcher.dispatch(action, context: ctx)

        XCTAssertEqual(navigatedScreen, "detail")
        XCTAssertEqual(navigatedParams?["podcastId"]?.intValue, 123)
    }

    func testDismissAction() async {
        let dispatcher = ActionDispatcher()
        let ctx = DataContext()
        var dismissed = false

        dispatcher.onDismiss = { dismissed = true }

        let action = ActionDefinition(actionType: "dismiss")
        await dispatcher.dispatch(action, context: ctx)
        XCTAssertTrue(dismissed)
    }

    func testSetStateAction() async {
        let dispatcher = ActionDispatcher()
        let ctx = DataContext()

        let action = ActionDefinition(actionType: "setState", key: "query", value: .string("test"))
        await dispatcher.dispatch(action, context: ctx)
        XCTAssertEqual(ctx.resolve("$.query")?.stringValue, "test")
    }

    func testSequenceAction() async {
        let dispatcher = ActionDispatcher()
        let ctx = DataContext()

        let action = ActionDefinition(actionType: "sequence", actions: [
            ActionDefinition(actionType: "setState", key: "a", value: .string("1")),
            ActionDefinition(actionType: "setState", key: "b", value: .string("2"))
        ])
        await dispatcher.dispatch(action, context: ctx)
        XCTAssertEqual(ctx.resolve("$.a")?.stringValue, "1")
        XCTAssertEqual(ctx.resolve("$.b")?.stringValue, "2")
    }

    func testCustomEventHandler() async {
        let dispatcher = ActionDispatcher()
        let ctx = DataContext(data: ["url": .string("https://example.com")])
        var receivedPayload: [String: Any]?

        dispatcher.registerEventHandler("openUrl") { payload in
            receivedPayload = payload
        }

        let action = ActionDefinition(actionType: "custom", event: "openUrl",
                                       payload: ["url": .string("$.url")])
        await dispatcher.dispatch(action, context: ctx)
        XCTAssertEqual(receivedPayload?["url"] as? String, "https://example.com")
    }
}

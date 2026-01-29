import Foundation
import Observation
import ViewEngine
import ActionSystem

/// Shared cache for live API data fetched per screen.
/// Fetch once, reuse everywhere — screen preview, component preview, etc.
@Observable
public class LiveDataCache {
    public static let shared = LiveDataCache()

    /// screen name → fetched DataContext snapshot
    private var contexts: [String: [String: AnyCodableValue]] = [:]

    /// screen name → all array items found in the response (flattened)
    private var itemPools: [String: [AnyCodableValue]] = [:]

    /// screens currently being fetched
    private var inFlight: Set<String> = []

    public func hasCached(_ screenName: String) -> Bool {
        contexts[screenName] != nil
    }

    public func cachedContext(_ screenName: String) -> DataContext? {
        guard let data = contexts[screenName] else { return nil }
        return DataContext(data: data)
    }

    public func cachedItems(_ screenName: String) -> [AnyCodableValue] {
        itemPools[screenName] ?? []
    }

    /// All items across every screen we've fetched.
    public var allCachedItems: [AnyCodableValue] {
        itemPools.values.flatMap { $0 }
    }

    public func invalidate(_ screenName: String) {
        contexts.removeValue(forKey: screenName)
        itemPools.removeValue(forKey: screenName)
    }

    public func invalidateAll() {
        contexts.removeAll()
        itemPools.removeAll()
    }

    /// Fetch live data for a screen by running its onLoad action.
    /// Returns cached result if already fetched. Force-refetches if `force` is true.
    @MainActor
    public func fetch(screenName: String, from bundles: [Bundle] = Bundle.allBundles, force: Bool = false) async -> FetchResult {
        if !force, let data = contexts[screenName] {
            return .cached(DataContext(data: data))
        }

        guard !inFlight.contains(screenName) else {
            return .error("Already fetching \(screenName)")
        }

        inFlight.insert(screenName)
        defer { inFlight.remove(screenName) }

        // Load screen JSON
        var screenURL: URL?
        for bundle in bundles {
            if let url = bundle.url(forResource: screenName, withExtension: "json") {
                screenURL = url
                break
            }
        }

        guard let url = screenURL,
              let data = try? Data(contentsOf: url),
              let node = try? JSONDecoder().decode(ViewNode.self, from: data) else {
            return .error("Could not load \(screenName).json")
        }

        guard let onLoad = node.actionProp("onLoad") else {
            return .error("Screen \"\(screenName)\" has no onLoad action")
        }

        let ctx = DataContext(data: ["env": .dictionary([:])])
        let dispatcher = ActionDispatcher()
        dispatcher.onNavigate = { _, _ in }
        dispatcher.onPresent = { _, _ in }
        dispatcher.onDismiss = {}

        await dispatcher.dispatch(onLoad, context: ctx)

        // Cache the raw data
        contexts[screenName] = ctx.data

        // Harvest all arrays as an item pool
        var items: [AnyCodableValue] = []
        for (_, value) in ctx.data {
            if let arr = value.arrayValue, !arr.isEmpty {
                items.append(contentsOf: arr)
            }
        }
        itemPools[screenName] = items

        return .fetched(ctx)
    }

    public enum FetchResult {
        case cached(DataContext)
        case fetched(DataContext)
        case error(String)

        public var context: DataContext? {
            switch self {
            case .cached(let c), .fetched(let c): return c
            case .error: return nil
            }
        }

        public var errorMessage: String? {
            if case .error(let msg) = self { return msg }
            return nil
        }
    }
}

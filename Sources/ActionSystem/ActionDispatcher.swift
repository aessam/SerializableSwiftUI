import Foundation
import ViewEngine
import PodcastData

public class ActionDispatcher: ObservableObject {
    public var onNavigate: ((String, [String: AnyCodableValue]) -> Void)?
    public var onPresent: ((String, [String: AnyCodableValue]) -> Void)?
    public var onDismiss: (() -> Void)?

    private let podcastService: PodcastService
    private var eventHandlers: [String: ([String: Any]) -> Void] = [:]

    public init(podcastService: PodcastService = .shared) {
        self.podcastService = podcastService
    }

    public func registerEventHandler(_ event: String, handler: @escaping ([String: Any]) -> Void) {
        eventHandlers[event] = handler
    }

    @MainActor
    public func dispatch(_ action: ActionDefinition, context: DataContext) async {
        print("[ActionDispatcher] Dispatching: \(action.actionType)")
        switch action.actionType {
        case "navigate":
            guard let screen = action.screen else { return }
            let params = resolveParams(action.params, context: context)
            onNavigate?(screen, params)

        case "present":
            guard let screen = action.screen else { return }
            let params = resolveParams(action.params, context: context)
            onPresent?(screen, params)

        case "dismiss":
            onDismiss?()

        case "api":
            await handleAPIAction(action, context: context)

        case "setState":
            guard let key = action.key else { return }
            if let value = action.value {
                let resolved = context.resolveValue(value)
                context.set(key, value: resolved)
            }

        case "custom":
            guard let event = action.event else { return }
            if let handler = eventHandlers[event] {
                var resolvedPayload: [String: Any] = [:]
                if let payload = action.payload {
                    for (k, v) in payload {
                        let resolved = context.resolveValue(v)
                        resolvedPayload[k] = resolved.stringValue ?? resolved.description
                    }
                }
                handler(resolvedPayload)
            }

        case "sequence":
            guard let actions = action.actions else { return }
            for (i, a) in actions.enumerated() {
                if i > 0 {
                    try? await Task.sleep(for: .seconds(2))
                }
                await dispatch(a, context: context)
            }

        default:
            break
        }
    }

    @MainActor
    private func handleAPIAction(_ action: ActionDefinition, context: DataContext) async {
        guard let endpoint = action.endpoint else {
            print("[ActionDispatcher] API action missing endpoint")
            return
        }
        let resolvedParams = resolveStringParams(action.params, context: context)
        print("[ActionDispatcher] API call: \(endpoint) params: \(resolvedParams)")

        for attempt in 1...3 {
            do {
                let result = try await podcastService.callEndpoint(path: endpoint, params: resolvedParams)
                if let resultKey = action.resultKey {
                    let codableResult = convertToAnyCodable(result)
                    if case .dictionary(let dict) = codableResult {
                        if let feed = dict["feed"]?.dictionaryValue, let results = feed["results"] {
                            context.set(resultKey, value: results)
                        } else if let results = dict["results"]?.arrayValue {
                            let normalized = results.map { item -> AnyCodableValue in
                                guard var d = item.dictionaryValue else { return item }
                                if d["name"] == nil, let trackName = d["trackName"] { d["name"] = trackName }
                                if d["id"] == nil, let trackId = d["trackId"] { d["id"] = trackId }
                                if d["artworkUrl100"] == nil, let art = d["artworkUrl600"] ?? d["artworkUrl100"] { d["artworkUrl100"] = art }
                                return .dictionary(d)
                            }
                            context.set(resultKey, value: .array(normalized))
                        } else {
                            context.set(resultKey, value: codableResult)
                        }
                    } else {
                        context.set(resultKey, value: codableResult)
                    }
                }
                return // success, exit retry loop
            } catch {
                fputs("[ActionDispatcher] API attempt \(attempt)/3 failed: \(endpoint) — \(error.localizedDescription)\n", stderr)
                if attempt < 3 {
                    try? await Task.sleep(for: .seconds(2))
                }
            }
        }
    }

    private func resolveParams(_ params: [String: AnyCodableValue]?, context: DataContext) -> [String: AnyCodableValue] {
        guard let params else { return [:] }
        var resolved: [String: AnyCodableValue] = [:]
        for (k, v) in params {
            resolved[k] = context.resolveValue(v)
        }
        return resolved
    }

    private func resolveStringParams(_ params: [String: AnyCodableValue]?, context: DataContext) -> [String: String] {
        guard let params else { return [:] }
        var resolved: [String: String] = [:]
        for (k, v) in params {
            let r = context.resolveValue(v)
            resolved[k] = r.stringValue ?? r.description
        }
        return resolved
    }

    private func convertToAnyCodable(_ value: Any) -> AnyCodableValue {
        if let dict = value as? [String: Any] {
            var result: [String: AnyCodableValue] = [:]
            for (k, v) in dict { result[k] = convertToAnyCodable(v) }
            return .dictionary(result)
        } else if let arr = value as? [Any] {
            return .array(arr.map { convertToAnyCodable($0) })
        } else if let s = value as? String {
            return .string(s)
        } else if let i = value as? Int {
            return .int(i)
        } else if let d = value as? Double {
            return .double(d)
        } else if let b = value as? Bool {
            return .bool(b)
        } else if value is NSNull {
            return .null
        }
        return .string("\(value)")
    }
}

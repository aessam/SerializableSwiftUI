import Foundation

public enum AnyCodableValue: Codable, Hashable, CustomStringConvertible {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([AnyCodableValue])
    case dictionary([String: AnyCodableValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? container.decode(Int.self) {
            self = .int(i)
        } else if let d = try? container.decode(Double.self) {
            self = .double(d)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let arr = try? container.decode([AnyCodableValue].self) {
            self = .array(arr)
        } else if let dict = try? container.decode([String: AnyCodableValue].self) {
            self = .dictionary(dict)
        } else {
            self = .null
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode(i)
        case .double(let d): try container.encode(d)
        case .bool(let b): try container.encode(b)
        case .array(let a): try container.encode(a)
        case .dictionary(let d): try container.encode(d)
        case .null: try container.encodeNil()
        }
    }

    public var description: String {
        switch self {
        case .string(let s): return s
        case .int(let i): return "\(i)"
        case .double(let d): return "\(d)"
        case .bool(let b): return "\(b)"
        case .array(let a): return "\(a)"
        case .dictionary(let d): return "\(d)"
        case .null: return ""
        }
    }

    public var stringValue: String? {
        switch self {
        case .string(let s): return s
        case .int(let i): return "\(i)"
        case .double(let d): return "\(d)"
        case .bool(let b): return b ? "true" : "false"
        default: return nil
        }
    }

    public var intValue: Int? {
        switch self {
        case .int(let i): return i
        case .double(let d): return Int(d)
        case .string(let s): return Int(s)
        default: return nil
        }
    }

    public var doubleValue: Double? {
        switch self {
        case .double(let d): return d
        case .int(let i): return Double(i)
        case .string(let s): return Double(s)
        default: return nil
        }
    }

    public var boolValue: Bool? {
        switch self {
        case .bool(let b): return b
        case .int(let i): return i != 0
        case .string(let s): return s == "true"
        default: return nil
        }
    }

    public var arrayValue: [AnyCodableValue]? {
        if case .array(let a) = self { return a }
        return nil
    }

    public var dictionaryValue: [String: AnyCodableValue]? {
        if case .dictionary(let d) = self { return d }
        return nil
    }

    public var isNull: Bool {
        if case .null = self { return true }
        return false
    }
}

public struct ActionDefinition: Codable, Hashable {
    public let actionType: String
    public let screen: String?
    public let params: [String: AnyCodableValue]?
    public let endpoint: String?
    public let resultKey: String?
    public let key: String?
    public let value: AnyCodableValue?
    public let event: String?
    public let payload: [String: AnyCodableValue]?
    public let actions: [ActionDefinition]?
    public let binding: String?

    public init(actionType: String, screen: String? = nil, params: [String: AnyCodableValue]? = nil,
                endpoint: String? = nil, resultKey: String? = nil, key: String? = nil,
                value: AnyCodableValue? = nil, event: String? = nil,
                payload: [String: AnyCodableValue]? = nil, actions: [ActionDefinition]? = nil,
                binding: String? = nil) {
        self.actionType = actionType; self.screen = screen; self.params = params
        self.endpoint = endpoint; self.resultKey = resultKey; self.key = key
        self.value = value; self.event = event; self.payload = payload
        self.actions = actions; self.binding = binding
    }
}

public struct TabDefinition: Codable, Hashable {
    public let title: String
    public let icon: String
    public let screen: String

    public init(title: String, icon: String, screen: String) {
        self.title = title; self.icon = icon; self.screen = screen
    }
}

public struct ViewNode: Codable, Hashable {
    public let type: String
    public let id: String?
    public let style: String?
    public let inlineStyle: [String: AnyCodableValue]?
    public let condition: String?
    public let children: [ViewNode]?
    public let props: [String: AnyCodableValue]?

    public init(type: String, id: String? = nil, style: String? = nil,
                inlineStyle: [String: AnyCodableValue]? = nil, condition: String? = nil,
                children: [ViewNode]? = nil, props: [String: AnyCodableValue]? = nil) {
        self.type = type; self.id = id; self.style = style
        self.inlineStyle = inlineStyle; self.condition = condition
        self.children = children; self.props = props
    }

    // Helper to extract typed props
    public func prop(_ key: String) -> AnyCodableValue? {
        props?[key]
    }

    public func stringProp(_ key: String) -> String? {
        props?[key]?.stringValue
    }

    public func intProp(_ key: String) -> Int? {
        props?[key]?.intValue
    }

    public func doubleProp(_ key: String) -> Double? {
        props?[key]?.doubleValue
    }

    public func boolProp(_ key: String) -> Bool? {
        props?[key]?.boolValue
    }

    public func nodeProp(_ key: String) -> ViewNode? {
        guard let dict = props?[key]?.dictionaryValue else { return nil }
        let data = try? JSONEncoder().encode(AnyCodableValue.dictionary(dict))
        guard let data else { return nil }
        return try? JSONDecoder().decode(ViewNode.self, from: data)
    }

    public func nodeArrayProp(_ key: String) -> [ViewNode]? {
        guard let arr = props?[key]?.arrayValue else { return nil }
        return arr.compactMap { item in
            guard let dict = item.dictionaryValue else { return nil }
            let data = try? JSONEncoder().encode(AnyCodableValue.dictionary(dict))
            guard let data else { return nil }
            return try? JSONDecoder().decode(ViewNode.self, from: data)
        }
    }

    public func actionProp(_ key: String) -> ActionDefinition? {
        guard let dict = props?[key]?.dictionaryValue else { return nil }
        let data = try? JSONEncoder().encode(AnyCodableValue.dictionary(dict))
        guard let data else { return nil }
        return try? JSONDecoder().decode(ActionDefinition.self, from: data)
    }

    public func tabsProp() -> [TabDefinition]? {
        guard let arr = props?["tabs"]?.arrayValue else { return nil }
        return arr.compactMap { item in
            guard let dict = item.dictionaryValue else { return nil }
            let data = try? JSONEncoder().encode(AnyCodableValue.dictionary(dict))
            guard let data else { return nil }
            return try? JSONDecoder().decode(TabDefinition.self, from: data)
        }
    }
}

public struct ComponentDefinition: Codable {
    public let parameters: [String]
    public let body: ViewNode

    public init(parameters: [String], body: ViewNode) {
        self.parameters = parameters; self.body = body
    }
}

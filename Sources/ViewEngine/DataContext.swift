import Foundation
import Observation

@Observable
public class DataContext {
    public var data: [String: AnyCodableValue]
    public let parent: DataContext?

    public init(data: [String: AnyCodableValue] = [:], parent: DataContext? = nil) {
        self.data = data
        self.parent = parent
    }

    public func child(with additionalData: [String: AnyCodableValue]) -> DataContext {
        DataContext(data: additionalData, parent: self)
    }

    public func resolve(_ path: String) -> AnyCodableValue? {
        let trimmed = path.trimmingCharacters(in: .whitespaces)

        // Check for transform pipeline
        if trimmed.contains(" | ") {
            let parts = trimmed.components(separatedBy: " | ")
            guard let first = parts.first else { return nil }
            let rawValue = resolveRawPath(first.trimmingCharacters(in: .whitespaces))
            var value = rawValue
            for i in 1..<parts.count {
                value = TransformPipeline.apply(parts[i].trimmingCharacters(in: .whitespaces), to: value)
            }
            return value
        }

        return resolveRawPath(trimmed)
    }

    private func resolveRawPath(_ path: String) -> AnyCodableValue? {
        // Must start with $
        guard path.hasPrefix("$") else { return nil }

        var keyPath = path
        if keyPath.hasPrefix("$.") {
            keyPath = String(keyPath.dropFirst(2))
        } else if keyPath == "$" {
            return .dictionary(allData())
        } else {
            keyPath = String(keyPath.dropFirst(1))
        }

        let components = keyPath.split(separator: ".").map(String.init)
        return resolveComponents(components)
    }

    private func resolveComponents(_ components: [String]) -> AnyCodableValue? {
        guard let first = components.first else { return nil }

        // Look in local data first, then parent
        if let value = data[first] {
            if components.count == 1 {
                return value
            }
            return dig(into: value, path: Array(components.dropFirst()))
        }

        // Try parent
        return parent?.resolveComponents(components)
    }

    private func dig(into value: AnyCodableValue, path: [String]) -> AnyCodableValue? {
        guard let first = path.first else { return value }

        switch value {
        case .dictionary(let dict):
            guard let next = dict[first] else { return nil }
            return path.count == 1 ? next : dig(into: next, path: Array(path.dropFirst()))
        case .array(let arr):
            guard let index = Int(first), index >= 0, index < arr.count else { return nil }
            return path.count == 1 ? arr[index] : dig(into: arr[index], path: Array(path.dropFirst()))
        default:
            return nil
        }
    }

    public func allData() -> [String: AnyCodableValue] {
        var merged = parent?.allData() ?? [:]
        for (k, v) in data { merged[k] = v }
        return merged
    }

    public func resolveString(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("\\$") {
            return String(trimmed.dropFirst(1))
        }
        if trimmed.hasPrefix("$") {
            if let resolved = resolve(trimmed) {
                return resolved.description
            }
            return ""
        }
        return value
    }

    public func resolveValue(_ value: AnyCodableValue) -> AnyCodableValue {
        switch value {
        case .string(let s):
            if s.trimmingCharacters(in: .whitespaces).hasPrefix("$") {
                return resolve(s) ?? .null
            }
            return value
        default:
            return value
        }
    }

    public func set(_ key: String, value: AnyCodableValue) {
        data[key] = value
    }
}

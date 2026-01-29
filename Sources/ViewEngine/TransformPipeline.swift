import Foundation

public struct TransformPipeline {
    public static func apply(_ transform: String, to value: AnyCodableValue?) -> AnyCodableValue? {
        let parts = transform.split(separator: ":", maxSplits: 1).map(String.init)
        let name = parts[0].trimmingCharacters(in: .whitespaces)
        let param = parts.count > 1 ? parts[1] : nil

        switch name {
        case "date":
            return applyDate(value, format: param ?? "MMM d, yyyy")
        case "duration":
            return applyDuration(value, format: param ?? "mm:ss")
        case "uppercase":
            guard let s = value?.stringValue else { return value }
            return .string(s.uppercased())
        case "lowercase":
            guard let s = value?.stringValue else { return value }
            return .string(s.lowercased())
        case "join":
            return applyJoin(value, separator: param ?? ",")
        case "default":
            if value == nil || value == .null {
                return .string(param ?? "")
            }
            return value
        case "truncate":
            guard let s = value?.stringValue, let len = Int(param ?? "") else { return value }
            if s.count > len {
                return .string(String(s.prefix(len)) + "…")
            }
            return value
        case "count":
            if let arr = value?.arrayValue {
                return .int(arr.count)
            }
            return .int(0)
        // Condition transforms handled by ConditionEvaluator
        case "exists", "empty", "!empty":
            return value
        default:
            return value
        }
    }

    private static func applyDate(_ value: AnyCodableValue?, format: String) -> AnyCodableValue? {
        guard let s = value?.stringValue else { return value }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = isoFormatter.date(from: s)
        if date == nil {
            isoFormatter.formatOptions = [.withInternetDateTime]
            date = isoFormatter.date(from: s)
        }
        guard let date else { return value }
        let outFormatter = DateFormatter()
        outFormatter.dateFormat = format
        return .string(outFormatter.string(from: date))
    }

    private static func applyDuration(_ value: AnyCodableValue?, format: String) -> AnyCodableValue? {
        guard let ms = value?.intValue else { return value }
        let totalSeconds = ms / 1000
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if format.contains("HH") || hours > 0 {
            return .string(String(format: "%d:%02d:%02d", hours, minutes, seconds))
        }
        return .string(String(format: "%d:%02d", minutes, seconds))
    }

    private static func applyJoin(_ value: AnyCodableValue?, separator: String) -> AnyCodableValue? {
        guard let arr = value?.arrayValue else { return value }
        let strings = arr.compactMap { $0.stringValue }
        return .string(strings.joined(separator: separator))
    }
}

import Foundation

public struct ConditionEvaluator {
    public static func evaluate(_ condition: String, context: DataContext) -> Bool {
        let trimmed = condition.trimmingCharacters(in: .whitespaces)

        // Check for pipe operators: exists, empty, !empty
        if trimmed.contains(" | ") {
            let parts = trimmed.components(separatedBy: " | ")
            guard parts.count >= 2 else { return false }
            let path = parts[0].trimmingCharacters(in: .whitespaces)
            let op = parts[1].trimmingCharacters(in: .whitespaces)
            let value = context.resolve(path)

            switch op {
            case "exists":
                return value != nil && !value!.isNull
            case "empty":
                return isEmpty(value)
            case "!empty":
                return !isEmpty(value)
            default:
                break
            }
        }

        // Check for comparison operators
        let operators = ["==", "!=", ">=", "<=", ">", "<"]
        for op in operators {
            if let range = trimmed.range(of: " \(op) ") {
                let lhs = String(trimmed[trimmed.startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let rhs = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                return evaluateComparison(lhs: lhs, op: op, rhs: rhs, context: context)
            }
        }

        // Plain binding — truthy check
        if trimmed.hasPrefix("$") {
            let value = context.resolve(trimmed)
            return isTruthy(value)
        }

        return false
    }

    private static func evaluateComparison(lhs: String, op: String, rhs: String, context: DataContext) -> Bool {
        let leftVal = resolveOperand(lhs, context: context)
        let rightVal = resolveOperand(rhs, context: context)

        switch op {
        case "==": return isEqual(leftVal, rightVal)
        case "!=": return !isEqual(leftVal, rightVal)
        case ">": return compareNumeric(leftVal, rightVal) == .orderedDescending
        case "<": return compareNumeric(leftVal, rightVal) == .orderedAscending
        case ">=":
            let r = compareNumeric(leftVal, rightVal)
            return r == .orderedDescending || r == .orderedSame
        case "<=":
            let r = compareNumeric(leftVal, rightVal)
            return r == .orderedAscending || r == .orderedSame
        default: return false
        }
    }

    private static func resolveOperand(_ operand: String, context: DataContext) -> AnyCodableValue? {
        let trimmed = operand.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("$") {
            return context.resolve(trimmed)
        }
        // String literal 'value'
        if trimmed.hasPrefix("'") && trimmed.hasSuffix("'") {
            return .string(String(trimmed.dropFirst().dropLast()))
        }
        // Number
        if let i = Int(trimmed) { return .int(i) }
        if let d = Double(trimmed) { return .double(d) }
        // Bool
        if trimmed == "true" { return .bool(true) }
        if trimmed == "false" { return .bool(false) }
        return .string(trimmed)
    }

    private static func isEqual(_ lhs: AnyCodableValue?, _ rhs: AnyCodableValue?) -> Bool {
        if lhs == nil && rhs == nil { return true }
        guard let l = lhs, let r = rhs else { return false }
        // Compare as strings for flexibility
        if let ls = l.stringValue, let rs = r.stringValue { return ls == rs }
        return l == r
    }

    private static func compareNumeric(_ lhs: AnyCodableValue?, _ rhs: AnyCodableValue?) -> ComparisonResult {
        guard let ld = lhs?.doubleValue, let rd = rhs?.doubleValue else { return .orderedSame }
        if ld < rd { return .orderedAscending }
        if ld > rd { return .orderedDescending }
        return .orderedSame
    }

    private static func isEmpty(_ value: AnyCodableValue?) -> Bool {
        guard let value else { return true }
        switch value {
        case .null: return true
        case .string(let s): return s.isEmpty
        case .array(let a): return a.isEmpty
        case .dictionary(let d): return d.isEmpty
        default: return false
        }
    }

    private static func isTruthy(_ value: AnyCodableValue?) -> Bool {
        guard let value else { return false }
        switch value {
        case .null: return false
        case .bool(let b): return b
        case .int(let i): return i != 0
        case .double(let d): return d != 0
        case .string(let s): return !s.isEmpty
        case .array(let a): return !a.isEmpty
        case .dictionary(let d): return !d.isEmpty
        }
    }
}

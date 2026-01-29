import Foundation
import Observation
import ViewEngine

@Observable
public class EditableViewNode: Identifiable {
    public let id: UUID
    public var type: String
    public var nodeId: String?
    public var style: String?
    public var inlineStyle: [String: AnyCodableValue]
    public var condition: String?
    public var props: [String: AnyCodableValue]
    public var children: [EditableViewNode]
    public weak var parent: EditableViewNode?

    public init(type: String, nodeId: String? = nil, style: String? = nil,
                inlineStyle: [String: AnyCodableValue] = [:], condition: String? = nil,
                props: [String: AnyCodableValue] = [:], children: [EditableViewNode] = []) {
        self.id = UUID()
        self.type = type
        self.nodeId = nodeId
        self.style = style
        self.inlineStyle = inlineStyle
        self.condition = condition
        self.props = props
        self.children = children
        for child in children {
            child.parent = self
        }
    }

    public convenience init(from viewNode: ViewNode) {
        let convertedChildren = (viewNode.children ?? []).map { EditableViewNode(from: $0) }
        // Convert nested ViewNode props (label, itemTemplate) into their dictionary form so they round-trip
        let convertedProps = viewNode.props ?? [:]
        self.init(
            type: viewNode.type,
            nodeId: viewNode.id,
            style: viewNode.style,
            inlineStyle: viewNode.inlineStyle ?? [:],
            condition: viewNode.condition,
            props: convertedProps,
            children: convertedChildren
        )
    }

    public func toViewNode() -> ViewNode {
        let childNodes: [ViewNode]? = children.isEmpty ? nil : children.map { $0.toViewNode() }
        let propsOut: [String: AnyCodableValue]? = props.isEmpty ? nil : props
        let inlineOut: [String: AnyCodableValue]? = inlineStyle.isEmpty ? nil : inlineStyle
        return ViewNode(
            type: type,
            id: nodeId,
            style: style,
            inlineStyle: inlineOut,
            condition: condition,
            children: childNodes,
            props: propsOut
        )
    }

    public func toJSON() -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? encoder.encode(toViewNode())) ?? Data()
    }

    /// Deep copy
    public func duplicate() -> EditableViewNode {
        EditableViewNode(from: toViewNode())
    }

    /// Display label for tree outline
    public var displayLabel: String {
        if let content = props["content"]?.stringValue, !content.isEmpty {
            let short = content.prefix(30)
            return "\(type): \(short)"
        }
        if let name = props["name"]?.stringValue {
            return "\(type): \(name)"
        }
        if let nodeId {
            return "\(type) #\(nodeId)"
        }
        return type
    }
}

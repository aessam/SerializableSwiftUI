import Foundation
import Observation
import ViewEngine
import OrderedCollections

@Observable
public class EditorDocument {
    public var screens: OrderedDictionary<String, EditableViewNode> = [:]
    public var components: OrderedDictionary<String, EditableComponentDef> = [:]
    public var theme: EditableTheme = EditableTheme()
    public var appRoot: EditableViewNode?

    public var selectedScreenName: String?
    public var selectedNode: EditableViewNode?

    public let undoManager = UndoManager()
    public let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    // MARK: - Selection helpers

    public var selectedScreen: EditableViewNode? {
        guard let name = selectedScreenName else { return nil }
        return screens[name]
    }

    // MARK: - Edit operations with undo

    public func setProperty(on node: EditableViewNode, key: String, value: AnyCodableValue?) {
        let oldValue = node.props[key]
        if let value {
            node.props[key] = value
        } else {
            node.props.removeValue(forKey: key)
        }
        undoManager.registerUndo(withTarget: self) { doc in
            doc.setProperty(on: node, key: key, value: oldValue)
        }
    }

    public func setType(on node: EditableViewNode, type: String) {
        let old = node.type
        node.type = type
        undoManager.registerUndo(withTarget: self) { doc in
            doc.setType(on: node, type: old)
        }
    }

    public func setStyle(on node: EditableViewNode, style: String?) {
        let old = node.style
        node.style = style
        undoManager.registerUndo(withTarget: self) { doc in
            doc.setStyle(on: node, style: old)
        }
    }

    public func setCondition(on node: EditableViewNode, condition: String?) {
        let old = node.condition
        node.condition = condition
        undoManager.registerUndo(withTarget: self) { doc in
            doc.setCondition(on: node, condition: old)
        }
    }

    public func setNodeId(on node: EditableViewNode, nodeId: String?) {
        let old = node.nodeId
        node.nodeId = nodeId
        undoManager.registerUndo(withTarget: self) { doc in
            doc.setNodeId(on: node, nodeId: old)
        }
    }

    public func setInlineStyle(on node: EditableViewNode, key: String, value: AnyCodableValue?) {
        let old = node.inlineStyle[key]
        if let value {
            node.inlineStyle[key] = value
        } else {
            node.inlineStyle.removeValue(forKey: key)
        }
        undoManager.registerUndo(withTarget: self) { doc in
            doc.setInlineStyle(on: node, key: key, value: old)
        }
    }

    public func addChild(to parent: EditableViewNode, node child: EditableViewNode, at index: Int) {
        let idx = min(index, parent.children.count)
        child.parent = parent
        parent.children.insert(child, at: idx)
        undoManager.registerUndo(withTarget: self) { doc in
            doc.removeChild(from: parent, at: idx)
        }
    }

    public func removeChild(from parent: EditableViewNode, at index: Int) {
        guard index < parent.children.count else { return }
        let removed = parent.children.remove(at: index)
        removed.parent = nil
        if selectedNode?.id == removed.id {
            selectedNode = parent
        }
        undoManager.registerUndo(withTarget: self) { doc in
            doc.addChild(to: parent, node: removed, at: index)
        }
    }

    public func moveChild(in parent: EditableViewNode, from source: Int, to destination: Int) {
        guard source < parent.children.count, destination <= parent.children.count else { return }
        let child = parent.children.remove(at: source)
        let adjustedDest = destination > source ? destination - 1 : destination
        parent.children.insert(child, at: adjustedDest)
        undoManager.registerUndo(withTarget: self) { doc in
            doc.moveChild(in: parent, from: adjustedDest, to: source)
        }
    }
}

// MARK: - Supporting types

@Observable
public class EditableComponentDef {
    public var parameters: [String]
    public var body: EditableViewNode

    public init(parameters: [String], body: EditableViewNode) {
        self.parameters = parameters
        self.body = body
    }

    public init(from def: ComponentDefinition) {
        self.parameters = def.parameters
        self.body = EditableViewNode(from: def.body)
    }

    public func toComponentDefinition() -> ComponentDefinition {
        ComponentDefinition(parameters: parameters, body: body.toViewNode())
    }
}

@Observable
public class EditableTheme {
    public var colors: OrderedDictionary<String, AnyCodableValue> = [:]
    public var fonts: OrderedDictionary<String, AnyCodableValue> = [:]
    public var presets: OrderedDictionary<String, [String: AnyCodableValue]> = [:]
}

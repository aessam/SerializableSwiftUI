import Foundation
import ViewEngine
import OrderedCollections

public struct ProjectManager {
    public let projectURL: URL

    public init(projectURL: URL) {
        self.projectURL = projectURL
    }

    // MARK: - Load

    public func loadDocument() -> EditorDocument {
        let doc = EditorDocument(projectURL: projectURL)

        // Load app.json
        if let appNode = loadViewNode(named: "app") {
            doc.appRoot = EditableViewNode(from: appNode)
        }

        // Load theme
        if let themeData = loadJSON(named: "theme") {
            if let colors = themeData["colors"]?.dictionaryValue {
                for (k, v) in colors.sorted(by: { $0.key < $1.key }) {
                    doc.theme.colors[k] = v
                }
            }
            if let fonts = themeData["fonts"]?.dictionaryValue {
                for (k, v) in fonts.sorted(by: { $0.key < $1.key }) {
                    doc.theme.fonts[k] = v
                }
            }
            if let presets = themeData["presets"]?.dictionaryValue {
                for (k, v) in presets.sorted(by: { $0.key < $1.key }) {
                    if let dict = v.dictionaryValue {
                        doc.theme.presets[k] = dict
                    }
                }
            }
        }

        // Load components
        if let compData = loadJSON(named: "components"),
           let comps = compData["components"]?.dictionaryValue {
            for (name, value) in comps.sorted(by: { $0.key < $1.key }) {
                if let data = try? JSONEncoder().encode(value),
                   let def = try? JSONDecoder().decode(ComponentDefinition.self, from: data) {
                    doc.components[name] = EditableComponentDef(from: def)
                }
            }
        }

        // Load screens (all .json files except app, theme, components)
        let reserved = Set(["app", "theme", "components"])
        let files = (try? FileManager.default.contentsOfDirectory(at: projectURL, includingPropertiesForKeys: nil)) ?? []
        for file in files.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            guard file.pathExtension == "json" else { continue }
            let name = file.deletingPathExtension().lastPathComponent
            guard !reserved.contains(name) else { continue }
            if let node = loadViewNode(named: name) {
                doc.screens[name] = EditableViewNode(from: node)
            }
        }

        if let firstName = doc.screens.keys.first {
            doc.selectedScreenName = firstName
        }

        return doc
    }

    // MARK: - Save

    public func save(document doc: EditorDocument) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        // Save app.json
        if let appRoot = doc.appRoot {
            let data = try encoder.encode(appRoot.toViewNode())
            try data.write(to: projectURL.appendingPathComponent("app.json"))
        }

        // Save screens
        for (name, root) in doc.screens {
            let data = try encoder.encode(root.toViewNode())
            try data.write(to: projectURL.appendingPathComponent("\(name).json"))
        }

        // Save components
        var compsDict: [String: AnyCodableValue] = [:]
        for (name, comp) in doc.components {
            let def = comp.toComponentDefinition()
            let data = try encoder.encode(def)
            let value = try JSONDecoder().decode(AnyCodableValue.self, from: data)
            compsDict[name] = value
        }
        let compsWrapper: [String: AnyCodableValue] = ["components": .dictionary(compsDict)]
        let compsData = try encoder.encode(compsWrapper)
        try compsData.write(to: projectURL.appendingPathComponent("components.json"))

        // Save theme
        var themeDict: [String: AnyCodableValue] = [:]
        if !doc.theme.colors.isEmpty {
            themeDict["colors"] = .dictionary(Dictionary(uniqueKeysWithValues: doc.theme.colors.map { ($0.key, $0.value) }))
        }
        if !doc.theme.fonts.isEmpty {
            themeDict["fonts"] = .dictionary(Dictionary(uniqueKeysWithValues: doc.theme.fonts.map { ($0.key, $0.value) }))
        }
        if !doc.theme.presets.isEmpty {
            var presetsDict: [String: AnyCodableValue] = [:]
            for (k, v) in doc.theme.presets {
                presetsDict[k] = .dictionary(v)
            }
            themeDict["presets"] = .dictionary(presetsDict)
        }
        let themeData = try encoder.encode(themeDict)
        try themeData.write(to: projectURL.appendingPathComponent("theme.json"))
    }

    // MARK: - Helpers

    private func loadViewNode(named name: String) -> ViewNode? {
        let url = projectURL.appendingPathComponent("\(name).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(ViewNode.self, from: data)
    }

    private func loadJSON(named name: String) -> [String: AnyCodableValue]? {
        let url = projectURL.appendingPathComponent("\(name).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([String: AnyCodableValue].self, from: data)
    }
}

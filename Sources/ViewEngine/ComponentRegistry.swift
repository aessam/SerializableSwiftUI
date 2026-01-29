import Foundation

public class ComponentRegistry {
    public static let shared = ComponentRegistry()

    private var components: [String: ComponentDefinition] = [:]

    private struct ComponentsFile: Codable {
        let components: [String: ComponentDefinition]
    }

    public func load(from bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "components", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }
        guard let file = try? JSONDecoder().decode(ComponentsFile.self, from: data) else { return }
        self.components = file.components
    }

    public func register(_ name: String, definition: ComponentDefinition) {
        components[name] = definition
    }

    public func resolve(_ name: String, parameters: [String: AnyCodableValue], context: DataContext) -> (ViewNode, DataContext)? {
        guard let component = components[name] else { return nil }

        var childData: [String: AnyCodableValue] = [:]
        for (paramName, paramValue) in parameters {
            childData[paramName] = context.resolveValue(paramValue)
        }

        let childContext = context.child(with: childData)
        return (component.body, childContext)
    }
}

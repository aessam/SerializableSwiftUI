import Foundation
import ViewEngine

public enum FieldType {
    case string, int, double, url, bool
    case array(of: String)
    case object(fields: [DataModelField])
}

public struct DataModelField {
    public let name: String
    public let type: FieldType
}

public struct DataModelDescriptor {
    public let name: String
    public let fields: [DataModelField]
}

public struct DataModelRegistry {
    public static let shared = DataModelRegistry()

    public let models: [DataModelDescriptor] = [
        DataModelDescriptor(name: "Podcast", fields: [
            DataModelField(name: "trackId", type: .int),
            DataModelField(name: "trackName", type: .string),
            DataModelField(name: "artistName", type: .string),
            DataModelField(name: "artworkUrl100", type: .url),
            DataModelField(name: "artworkUrl600", type: .url),
            DataModelField(name: "primaryGenreName", type: .string),
            DataModelField(name: "trackCount", type: .int),
            DataModelField(name: "genres", type: .array(of: "String")),
        ]),
        DataModelDescriptor(name: "Episode", fields: [
            DataModelField(name: "trackId", type: .int),
            DataModelField(name: "trackName", type: .string),
            DataModelField(name: "description", type: .string),
            DataModelField(name: "releaseDate", type: .string),
            DataModelField(name: "trackTimeMillis", type: .int),
            DataModelField(name: "episodeUrl", type: .url),
            DataModelField(name: "artistName", type: .string),
        ]),
    ]

    public func allFieldPaths() -> [String] {
        var paths: [String] = ["$.env.searchQuery"]
        for model in models {
            let prefix = model.name.lowercased()
            for field in model.fields {
                paths.append("$.\(prefix).\(field.name)")
            }
        }
        return paths
    }
}

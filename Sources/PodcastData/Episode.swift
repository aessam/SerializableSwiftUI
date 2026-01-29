import Foundation

public struct EpisodeLookupResult: Codable {
    public let resultCount: Int
    public let results: [EpisodeResultItem]

    public init(resultCount: Int, results: [EpisodeResultItem]) {
        self.resultCount = resultCount
        self.results = results
    }
}

public struct EpisodeResultItem: Codable {
    public let wrapperType: String
    public let trackId: Int?
    public let trackName: String?
    public let description: String?
    public let releaseDate: String?
    public let trackTimeMillis: Int?
    public let episodeUrl: String?
    public let kind: String?

    public init(wrapperType: String, trackId: Int? = nil, trackName: String? = nil, description: String? = nil, releaseDate: String? = nil, trackTimeMillis: Int? = nil, episodeUrl: String? = nil, kind: String? = nil) {
        self.wrapperType = wrapperType
        self.trackId = trackId
        self.trackName = trackName
        self.description = description
        self.releaseDate = releaseDate
        self.trackTimeMillis = trackTimeMillis
        self.episodeUrl = episodeUrl
        self.kind = kind
    }
}

public struct Episode: Codable, Identifiable, Hashable {
    public let trackId: Int
    public let trackName: String
    public let description: String?
    public let releaseDate: String?
    public let trackTimeMillis: Int?
    public let episodeUrl: String?

    public var id: Int { trackId }

    public init(trackId: Int, trackName: String, description: String? = nil, releaseDate: String? = nil, trackTimeMillis: Int? = nil, episodeUrl: String? = nil) {
        self.trackId = trackId
        self.trackName = trackName
        self.description = description
        self.releaseDate = releaseDate
        self.trackTimeMillis = trackTimeMillis
        self.episodeUrl = episodeUrl
    }
}

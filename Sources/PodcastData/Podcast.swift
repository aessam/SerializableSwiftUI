import Foundation

public struct PodcastSearchResult: Codable {
    public let resultCount: Int
    public let results: [Podcast]

    public init(resultCount: Int, results: [Podcast]) {
        self.resultCount = resultCount
        self.results = results
    }
}

public struct Podcast: Codable, Identifiable, Hashable {
    public let trackId: Int
    public let trackName: String
    public let artistName: String
    public let artworkUrl600: String?
    public let collectionViewUrl: String?
    public let feedUrl: String?
    public let primaryGenreName: String?
    public let genres: [String]?
    public let trackCount: Int?
    public let releaseDate: String?
    public let contentAdvisoryRating: String?

    public var id: Int { trackId }

    public init(trackId: Int, trackName: String, artistName: String, artworkUrl600: String? = nil, collectionViewUrl: String? = nil, feedUrl: String? = nil, primaryGenreName: String? = nil, genres: [String]? = nil, trackCount: Int? = nil, releaseDate: String? = nil, contentAdvisoryRating: String? = nil) {
        self.trackId = trackId
        self.trackName = trackName
        self.artistName = artistName
        self.artworkUrl600 = artworkUrl600
        self.collectionViewUrl = collectionViewUrl
        self.feedUrl = feedUrl
        self.primaryGenreName = primaryGenreName
        self.genres = genres
        self.trackCount = trackCount
        self.releaseDate = releaseDate
        self.contentAdvisoryRating = contentAdvisoryRating
    }
}

import Foundation
import Observation

@Observable
public class PodcastService {
    public static let shared = PodcastService()
    private let baseURL = "https://itunes.apple.com"
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func searchPodcasts(term: String) async throws -> [Podcast] {
        let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? term
        let url = URL(string: "\(baseURL)/search?term=\(encoded)&media=podcast")!
        let (data, _) = try await session.data(from: url)
        let result = try JSONDecoder().decode(PodcastSearchResult.self, from: data)
        return result.results
    }

    public func lookupPodcast(id: Int) async throws -> Podcast? {
        let url = URL(string: "\(baseURL)/lookup?id=\(id)")!
        let (data, _) = try await session.data(from: url)
        let result = try JSONDecoder().decode(PodcastSearchResult.self, from: data)
        return result.results.first
    }

    public func lookupEpisodes(podcastId: Int) async throws -> [Episode] {
        let url = URL(string: "\(baseURL)/lookup?id=\(podcastId)&entity=podcastEpisode")!
        let (data, _) = try await session.data(from: url)
        let result = try JSONDecoder().decode(EpisodeLookupResult.self, from: data)
        return result.results
            .filter { $0.wrapperType == "podcastEpisode" }
            .compactMap { item in
                guard let trackId = item.trackId, let trackName = item.trackName else { return nil }
                return Episode(
                    trackId: trackId,
                    trackName: trackName,
                    description: item.description,
                    releaseDate: item.releaseDate,
                    trackTimeMillis: item.trackTimeMillis,
                    episodeUrl: item.episodeUrl
                )
            }
    }

    public func browsePodcasts(genreId: Int) async throws -> [Podcast] {
        let url = URL(string: "\(baseURL)/search?term=podcast&genreId=\(genreId)&limit=25")!
        let (data, _) = try await session.data(from: url)
        let result = try JSONDecoder().decode(PodcastSearchResult.self, from: data)
        return result.results
    }

    public func callEndpoint(path: String, params: [String: String]) async throws -> Any {
        let url: URL
        if path.hasPrefix("http") {
            // Full URL — use as-is, append params if any
            var components = URLComponents(string: path)!
            if !params.isEmpty {
                components.queryItems = (components.queryItems ?? []) + params.map { URLQueryItem(name: $0.key, value: $0.value) }
            }
            url = components.url!
        } else {
            // Relative path — use iTunes base URL
            var components = URLComponents(string: "\(baseURL)\(path)")!
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
            url = components.url!
        }
        let (data, _) = try await session.data(from: url)
        return try JSONSerialization.jsonObject(with: data)
    }
}

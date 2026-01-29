import Foundation
import Observation

@Observable
public class PodcastService {
    public static let shared = PodcastService()
    private let baseURL = "https://itunes.apple.com"
    private let session: URLSession
    private let cache: DiskResponseCache

    public init(session: URLSession = .shared, cacheTTL: TimeInterval = 3600) {
        self.session = session
        self.cache = DiskResponseCache(ttl: cacheTTL)
    }

    public func searchPodcasts(term: String) async throws -> [Podcast] {
        let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? term
        let url = URL(string: "\(baseURL)/search?term=\(encoded)&media=podcast")!
        let data = try await cachedData(for: url)
        let result = try JSONDecoder().decode(PodcastSearchResult.self, from: data)
        return result.results
    }

    public func lookupPodcast(id: Int) async throws -> Podcast? {
        let url = URL(string: "\(baseURL)/lookup?id=\(id)")!
        let data = try await cachedData(for: url)
        let result = try JSONDecoder().decode(PodcastSearchResult.self, from: data)
        return result.results.first
    }

    public func lookupEpisodes(podcastId: Int) async throws -> [Episode] {
        let url = URL(string: "\(baseURL)/lookup?id=\(podcastId)&entity=podcastEpisode")!
        let data = try await cachedData(for: url)
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
        let data = try await cachedData(for: url)
        let result = try JSONDecoder().decode(PodcastSearchResult.self, from: data)
        return result.results
    }

    public func callEndpoint(path: String, params: [String: String]) async throws -> Any {
        let url: URL
        if path.hasPrefix("http") {
            var components = URLComponents(string: path)!
            if !params.isEmpty {
                components.queryItems = (components.queryItems ?? []) + params.map { URLQueryItem(name: $0.key, value: $0.value) }
            }
            url = components.url!
        } else {
            var components = URLComponents(string: "\(baseURL)\(path)")!
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
            url = components.url!
        }
        let data = try await cachedData(for: url)
        return try JSONSerialization.jsonObject(with: data)
    }

    /// Clear all cached responses
    public func clearCache() {
        cache.clear()
    }

    // MARK: - Internal

    private func cachedData(for url: URL) async throws -> Data {
        if let cached = cache.read(for: url) {
            return cached
        }
        let (data, _) = try await session.data(from: url)
        cache.write(data, for: url)
        return data
    }
}

// MARK: - Disk-backed response cache

private class DiskResponseCache {
    private let cacheDir: URL
    private let ttl: TimeInterval

    init(ttl: TimeInterval) {
        self.ttl = ttl
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDir = base.appendingPathComponent("SerializableSwiftUI/api_cache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    func read(for url: URL) -> Data? {
        let file = cacheFile(for: url)
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }

        // Check TTL
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: file.path),
              let modified = attrs[.modificationDate] as? Date,
              Date().timeIntervalSince(modified) < ttl else {
            try? FileManager.default.removeItem(at: file)
            return nil
        }

        return try? Data(contentsOf: file)
    }

    func write(_ data: Data, for url: URL) {
        let file = cacheFile(for: url)
        try? data.write(to: file, options: .atomic)
    }

    func clear() {
        try? FileManager.default.removeItem(at: cacheDir)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    private func cacheFile(for url: URL) -> URL {
        let key = url.absoluteString
        let hash = key.utf8.reduce(into: UInt64(5381)) { h, c in
            h = h &* 33 &+ UInt64(c)
        }
        return cacheDir.appendingPathComponent("\(hash).json")
    }
}

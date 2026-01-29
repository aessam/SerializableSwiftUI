import Foundation
import ViewEngine

public struct MockDataProvider {
    public static func context(for screenName: String) -> DataContext {
        let ctx = DataContext(data: ["env": .dictionary(["searchQuery": .string("")])])

        switch screenName {
        case "browse":
            ctx.set("topPodcasts", value: .array(samplePodcasts))
            ctx.set("recentEpisodes", value: .array(sampleEpisodes))
        case "search":
            ctx.set("results", value: .array(samplePodcasts))
        case "podcast_detail":
            ctx.set("podcast", value: samplePodcasts[0])
            ctx.set("episodes", value: .array(sampleEpisodes))
        case "episode_detail":
            ctx.set("episode", value: sampleEpisodes[0])
        default:
            break
        }

        return ctx
    }

    // MARK: - Component preview data

    /// All sample items keyed by parameter name convention.
    /// Components declare parameters like "podcast", "episode" —
    /// this maps those names to a pool of sample values.
    public static let samplePools: [String: [AnyCodableValue]] = [
        "podcast": samplePodcasts,
        "episode": sampleEpisodes,
        "item": samplePodcasts + sampleEpisodes,
    ]

    /// Build a context for a component with the given parameter names,
    /// picking a random sample value for each from the pool.
    public static func randomComponentContext(parameters: [String], seed: Int = 0) -> DataContext {
        let ctx = DataContext(data: ["env": .dictionary(["searchQuery": .string("")])])
        for param in parameters {
            let pool = samplePools[param] ?? samplePools["item"] ?? []
            guard !pool.isEmpty else { continue }
            let index = seed >= 0 ? (seed % pool.count) : Int.random(in: 0..<pool.count)
            ctx.set(param, value: pool[index])
        }
        return ctx
    }

    /// Build a context from live-fetched data, mapping component parameters
    /// to items from the fetched arrays.
    public static func contextFromLiveData(parameters: [String], liveData: [String: AnyCodableValue], seed: Int) -> DataContext {
        let ctx = DataContext(data: ["env": .dictionary(["searchQuery": .string("")])])
        for param in parameters {
            // Try to find a matching array in live data
            if let pool = findPool(for: param, in: liveData) {
                guard !pool.isEmpty else { continue }
                let index = seed >= 0 ? (seed % pool.count) : Int.random(in: 0..<pool.count)
                ctx.set(param, value: pool[index])
            }
        }
        return ctx
    }

    /// Searches live data for an array that likely matches a parameter name.
    private static func findPool(for param: String, in data: [String: AnyCodableValue]) -> [AnyCodableValue]? {
        // Direct match
        if let arr = data[param]?.arrayValue { return arr }
        // Look for plural/collection keys
        let plural = param + "s"
        if let arr = data[plural]?.arrayValue { return arr }
        // Search all top-level arrays
        for (_, value) in data {
            if let arr = value.arrayValue, !arr.isEmpty {
                return arr
            }
        }
        return nil
    }

    // MARK: - Sample data pools

    static let samplePodcasts: [AnyCodableValue] = [
        .dictionary([
            "trackId": .int(1),
            "trackName": .string("The Daily"),
            "name": .string("The Daily"),
            "artistName": .string("The New York Times"),
            "artworkUrl100": .string("https://is1-ssl.mzstatic.com/image/thumb/Podcasts116/v4/4a/72/2e/4a722e00-0826-c44d-b546-789158e30498/mza_14aborodwtfwcaxi.jpeg/100x100bb.jpg"),
            "artworkUrl600": .string("https://is1-ssl.mzstatic.com/image/thumb/Podcasts116/v4/4a/72/2e/4a722e00-0826-c44d-b546-789158e30498/mza_14adorodwtfwcaxi.jpeg/600x600bb.jpg"),
            "primaryGenreName": .string("News"),
            "trackCount": .int(2500),
            "genres": .array([.string("News"), .string("Daily News")])
        ]),
        .dictionary([
            "trackId": .int(2),
            "trackName": .string("Serial"),
            "name": .string("Serial"),
            "artistName": .string("Serial Productions"),
            "artworkUrl100": .string("https://is1-ssl.mzstatic.com/image/thumb/Podcasts126/v4/89/51/e4/8951e4e1-b438-c41b-5aa1-53e36e43755f/mza_8766119951793498893.jpeg/100x100bb.jpg"),
            "artworkUrl600": .string("https://is1-ssl.mzstatic.com/image/thumb/Podcasts126/v4/89/51/e4/8951e4e1-b438-c41b-5aa1-53e36e43755f/mza_8766119951793498893.jpeg/600x600bb.jpg"),
            "primaryGenreName": .string("True Crime"),
            "trackCount": .int(54),
            "genres": .array([.string("True Crime"), .string("Society & Culture")])
        ]),
        .dictionary([
            "trackId": .int(3),
            "trackName": .string("Lex Fridman Podcast"),
            "name": .string("Lex Fridman Podcast"),
            "artistName": .string("Lex Fridman"),
            "artworkUrl100": .string("https://is1-ssl.mzstatic.com/image/thumb/Podcasts116/v4/26/11/e3/2611e3fe-4b1e-de5b-4e11-5e3db98d498e/mza_14026498044521498498.jpg/100x100bb.jpg"),
            "artworkUrl600": .string("https://is1-ssl.mzstatic.com/image/thumb/Podcasts116/v4/26/11/e3/2611e3fe-4b1e-de5b-4e11-5e3db98d498e/mza_14026498044521498498.jpg/600x600bb.jpg"),
            "primaryGenreName": .string("Technology"),
            "trackCount": .int(450),
            "genres": .array([.string("Technology"), .string("Science")])
        ]),
        .dictionary([
            "trackId": .int(4),
            "trackName": .string("Huberman Lab"),
            "name": .string("Huberman Lab"),
            "artistName": .string("Scicomm Media"),
            "artworkUrl100": .string("https://is1-ssl.mzstatic.com/image/thumb/Podcasts116/v4/11/04/c3/1104c33a-3a5c-9c30-c395-07de3b0a2afb/mza_7005498330750505192.jpg/100x100bb.jpg"),
            "artworkUrl600": .string("https://is1-ssl.mzstatic.com/image/thumb/Podcasts116/v4/11/04/c3/1104c33a-3a5c-9c30-c395-07de3b0a2afb/mza_7005498330750505192.jpg/600x600bb.jpg"),
            "primaryGenreName": .string("Health & Fitness"),
            "trackCount": .int(200),
            "genres": .array([.string("Health & Fitness"), .string("Science")])
        ]),
        .dictionary([
            "trackId": .int(5),
            "trackName": .string("Conan O'Brien Needs a Friend"),
            "name": .string("Conan O'Brien Needs a Friend"),
            "artistName": .string("Team Coco & Earwolf"),
            "artworkUrl100": .string("https://is1-ssl.mzstatic.com/image/thumb/Podcasts126/v4/c4/a2/5c/c4a25cf4-7aac-1bd5-e09a-63fa07a078e6/mza_14511105199673585905.jpg/100x100bb.jpg"),
            "artworkUrl600": .string("https://is1-ssl.mzstatic.com/image/thumb/Podcasts126/v4/c4/a2/5c/c4a25cf4-7aac-1bd5-e09a-63fa07a078e6/mza_14511105199673585905.jpg/600x600bb.jpg"),
            "primaryGenreName": .string("Comedy"),
            "trackCount": .int(300),
            "genres": .array([.string("Comedy"), .string("Interviews")])
        ]),
    ]

    static let sampleEpisodes: [AnyCodableValue] = [
        .dictionary([
            "trackId": .int(101),
            "trackName": .string("The Secret History of the Internet"),
            "name": .string("The Secret History of the Internet"),
            "description": .string("How a small group of researchers built the network that changed everything, and what they got wrong."),
            "releaseDate": .string("2025-01-15T00:00:00Z"),
            "trackTimeMillis": .int(3600000),
            "artistName": .string("The Daily")
        ]),
        .dictionary([
            "trackId": .int(102),
            "trackName": .string("Inside the AI Arms Race"),
            "name": .string("Inside the AI Arms Race"),
            "description": .string("Nations are racing to develop the most powerful AI systems. What does this mean for the future?"),
            "releaseDate": .string("2025-02-10T00:00:00Z"),
            "trackTimeMillis": .int(4200000),
            "artistName": .string("Serial Productions")
        ]),
        .dictionary([
            "trackId": .int(103),
            "trackName": .string("Sleep, Stress & Performance"),
            "name": .string("Sleep, Stress & Performance"),
            "description": .string("The science of optimizing your sleep for better cognitive performance and reduced stress."),
            "releaseDate": .string("2025-03-05T00:00:00Z"),
            "trackTimeMillis": .int(5400000),
            "artistName": .string("Huberman Lab")
        ]),
        .dictionary([
            "trackId": .int(104),
            "trackName": .string("Jeff Goldblum Returns"),
            "name": .string("Jeff Goldblum Returns"),
            "description": .string("Jeff Goldblum is back and more Jeff Goldblum-y than ever. Chaos theory, jazz piano, and friendship."),
            "releaseDate": .string("2025-04-20T00:00:00Z"),
            "trackTimeMillis": .int(2700000),
            "artistName": .string("Team Coco")
        ]),
        .dictionary([
            "trackId": .int(105),
            "trackName": .string("The Future of Robotics"),
            "name": .string("The Future of Robotics"),
            "description": .string("A deep conversation about humanoid robots, autonomy, and the path to general intelligence."),
            "releaseDate": .string("2025-05-12T00:00:00Z"),
            "trackTimeMillis": .int(7200000),
            "artistName": .string("Lex Fridman")
        ]),
    ]
}

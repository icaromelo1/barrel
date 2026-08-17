import Foundation

actor GameService {
    static let shared = GameService()

    private var games: [Game] = []
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadAll() throws -> [Game] {
        let dbURL = StorageManager.shared.gamesDBURL
        guard FileManager.default.fileExists(atPath: dbURL.path) else {
            // No games.json yet at the current storage root (e.g. right after
            // switching to a fresh/different root) — reset in-memory state too,
            // otherwise stale entries from a previous root linger forever.
            games = []
            return []
        }
        let data = try Data(contentsOf: dbURL)
        games = try decoder.decode([Game].self, from: data)
        return games
    }

    func add(name: String, exePath: String, bottleId: UUID, launchArgs: String = "") throws -> Game {
        let game = Game(name: name, exePath: exePath, bottleId: bottleId, launchArgs: launchArgs)
        games.append(game)
        try persist()
        return game
    }

    func remove(id: UUID) throws {
        games.removeAll { $0.id == id }
        try persist()
    }

    func update(_ game: Game) throws {
        guard let index = games.firstIndex(where: { $0.id == game.id }) else {
            throw BarrelError.gameNotFound
        }
        games[index] = game
        try persist()
    }

    func games(for bottleId: UUID) -> [Game] {
        games.filter { $0.bottleId == bottleId }
    }

    private func persist() throws {
        let data = try encoder.encode(games)
        try data.write(to: StorageManager.shared.gamesDBURL)
    }
}

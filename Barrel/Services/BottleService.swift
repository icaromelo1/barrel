import Foundation

actor BottleService {
    static let shared = BottleService()

    private var bottles: [Bottle] = []
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - CRUD

    func loadAll() throws -> [Bottle] {
        let bottlesDir = StorageManager.shared.bottlesDirectory
        let contents = try FileManager.default.contentsOfDirectory(
            at: bottlesDir,
            includingPropertiesForKeys: nil
        )
        bottles = try contents.compactMap { dir -> Bottle? in
            let metaFile = dir.appending(path: "barrel.json")
            guard FileManager.default.fileExists(atPath: metaFile.path) else { return nil }
            let data = try Data(contentsOf: metaFile)
            return try decoder.decode(Bottle.self, from: data)
        }
        return bottles.sorted { $0.createdAt < $1.createdAt }
    }

    func create(name: String, config: BottleConfig = .default) async throws -> Bottle {
        let bottle = Bottle(name: name, config: config)
        let bottleDir = StorageManager.shared.bottlesDirectory.appending(path: bottle.id.uuidString)

        try FileManager.default.createDirectory(at: bottle.prefixURL, withIntermediateDirectories: true)
        try await WineService.shared.bootPrefix(bottle.prefixURL)
        try save(bottle)

        bottles.append(bottle)
        return bottle
    }

    func delete(_ bottle: Bottle) throws {
        let bottleDir = StorageManager.shared.bottlesDirectory.appending(path: bottle.id.uuidString)
        try FileManager.default.removeItem(at: bottleDir)
        bottles.removeAll { $0.id == bottle.id }
    }

    func update(_ bottle: Bottle) throws {
        try save(bottle)
        if let index = bottles.firstIndex(where: { $0.id == bottle.id }) {
            bottles[index] = bottle
        }
    }

    // MARK: - Persistência

    private func save(_ bottle: Bottle) throws {
        let data = try encoder.encode(bottle)
        let bottleDir = StorageManager.shared.bottlesDirectory.appending(path: bottle.id.uuidString)
        try FileManager.default.createDirectory(at: bottleDir, withIntermediateDirectories: true)
        try data.write(to: bottle.metadataURL)
    }
}

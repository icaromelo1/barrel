import Foundation

struct Game: Identifiable, Codable {
    let id: UUID
    var name: String
    var exePath: String
    var bottleId: UUID
    var launchArgs: String
    var artworkURL: URL?
    var addedAt: Date

    init(id: UUID = UUID(), name: String, exePath: String, bottleId: UUID, launchArgs: String = "") {
        self.id = id
        self.name = name
        self.exePath = exePath
        self.bottleId = bottleId
        self.launchArgs = launchArgs
        self.artworkURL = nil
        self.addedAt = Date()
    }
}

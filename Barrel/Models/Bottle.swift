import Foundation

struct Bottle: Identifiable, Codable {
    let id: UUID
    var name: String
    var wineVersion: String
    var config: BottleConfig
    var createdAt: Date
    var games: [UUID]

    init(id: UUID = UUID(), name: String, wineVersion: String = "", config: BottleConfig = .default) {
        self.id = id
        self.name = name
        self.wineVersion = wineVersion
        self.config = config
        self.createdAt = Date()
        self.games = []
    }

    var prefixURL: URL {
        StorageManager.shared.bottlesDirectory
            .appending(path: id.uuidString)
            .appending(path: "prefix")
    }

    var metadataURL: URL {
        StorageManager.shared.bottlesDirectory
            .appending(path: id.uuidString)
            .appending(path: "barrel.json")
    }
}

struct BottleConfig: Codable {
    var arch: WineArch
    var renderer: Renderer
    var esync: Bool
    var msync: Bool

    static let `default` = BottleConfig(arch: .win64, renderer: .dxvk, esync: true, msync: true)
}

enum WineArch: String, Codable, CaseIterable {
    case win32 = "win32"
    case win64 = "win64"
}

enum Renderer: String, Codable, CaseIterable {
    case dxvk = "DXVK"
    case metal = "D3DMetal"
    case gl = "OpenGL"
}

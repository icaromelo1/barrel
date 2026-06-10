import Foundation

// MARK: - Preset

enum BottlePreset: String, Codable, CaseIterable {
    case steam, gaming, compatibility

    var label: String {
        switch self { case .steam: "Steam"; case .gaming: "Gaming"; case .compatibility: "Compatibility" }
    }
    var subtitle: String {
        switch self {
        case .steam:         return "Install Steam and play your library"
        case .gaming:        return "Optimized for modern PC games"
        case .compatibility: return "For older or demanding titles"
        }
    }
    var icon: String {
        switch self { case .steam: "gamecontroller.fill"; case .gaming: "bolt.fill"; case .compatibility: "gearshape.2.fill" }
    }
    var defaultRenderer: Renderer {
        switch self { case .steam, .gaming: return .dxvk; case .compatibility: return .gl }
    }
    var defaultName: String {
        switch self { case .steam: "Steam"; case .gaming: "My Games"; case .compatibility: "Classic Games" }
    }
    var gradient: (start: String, end: String) {
        switch self {
        case .steam:         return ("#1b2838", "#2a475e")
        case .gaming:        return ("#9a6bff", "#6f54f0")
        case .compatibility: return ("#ff8a3d", "#ff5a52")
        }
    }
    // Winetricks verbs + "dxvk" sentinel for manual install
    var depIds: [String] {
        switch self {
        case .steam:         return ["vcrun2022", "corefonts"]
        case .gaming:        return ["dxvk", "vcrun2022", "d3dcompiler_47"]
        case .compatibility: return ["vcrun2022", "corefonts"]
        }
    }
}

// MARK: - Init status (transient, only meaningful while app is running)

enum BottleInitStatus: String, Codable {
    case pending  // wineboot + deps not yet done
    case ready    // fully initialized
    case failed   // initialization failed
}

// MARK: - Bottle

struct Bottle: Identifiable, Codable {
    let id: UUID
    var name: String
    var wineVersion: String
    var config: BottleConfig
    var preset: BottlePreset?
    var initStatus: BottleInitStatus
    var createdAt: Date
    var games: [UUID]

    init(id: UUID = UUID(), name: String, wineVersion: String = "",
         config: BottleConfig = .default, preset: BottlePreset? = nil) {
        self.id = id
        self.name = name
        self.wineVersion = wineVersion
        self.config = config
        self.preset = preset
        self.initStatus = .pending
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

    // Backward-compatible decoding: old JSON without initStatus defaults to .ready
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id         = try c.decode(UUID.self, forKey: .id)
        name       = try c.decode(String.self, forKey: .name)
        wineVersion = try c.decodeIfPresent(String.self, forKey: .wineVersion) ?? ""
        config     = try c.decode(BottleConfig.self, forKey: .config)
        preset     = try c.decodeIfPresent(BottlePreset.self, forKey: .preset)
        initStatus = try c.decodeIfPresent(BottleInitStatus.self, forKey: .initStatus) ?? .ready
        createdAt  = try c.decode(Date.self, forKey: .createdAt)
        games      = try c.decodeIfPresent([UUID].self, forKey: .games) ?? []
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

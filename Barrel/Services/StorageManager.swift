import Foundation

/// Gerencia onde os dados pesados ficam armazenados.
/// Prioriza o SSD externo se montado; cai para ~/Library como fallback.
final class StorageManager {
    static let shared = StorageManager()

    private let ssdPath = "/Volumes/icaro_ssd/barrel-data"
    private let fallbackPath: URL = {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "Barrel")
    }()

    var isExternalSSDMounted: Bool {
        FileManager.default.fileExists(atPath: ssdPath)
    }

    var rootDirectory: URL {
        isExternalSSDMounted
            ? URL(filePath: ssdPath)
            : fallbackPath
    }

    var bottlesDirectory: URL { rootDirectory.appending(path: "bottles") }
    var wineDirectory: URL    { rootDirectory.appending(path: "wine") }
    var cacheDirectory: URL   { rootDirectory.appending(path: "cache") }
    var gamesDBURL: URL       { rootDirectory.appending(path: "games.json") }

    private init() {
        createDirectoriesIfNeeded()
    }

    private func createDirectoriesIfNeeded() {
        let dirs = [bottlesDirectory, wineDirectory, cacheDirectory]
        for dir in dirs {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    func storageInfo() -> String {
        isExternalSSDMounted
            ? "SSD externo: \(ssdPath)"
            : "Disco interno (fallback): \(fallbackPath.path)"
    }
}

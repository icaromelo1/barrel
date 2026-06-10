import Foundation

actor DownloadService {
    static let shared = DownloadService()

    // Gcenx publica builds do Wine para macOS neste repositório
    private let gcenxReleasesURL = URL(string: "https://api.github.com/repos/Gcenx/macOS_Wine_builds/releases/latest")!

    func latestWineBuild() async throws -> WineBuild {
        var request = URLRequest(url: gcenxReleasesURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, _) = try await URLSession.shared.data(for: request)
        let release = try JSONDecoder().decode(GithubRelease.self, from: data)

        // Prioriza CX Wine (CrossOver fork) para melhor compatibilidade macOS
        let asset = release.assets.first { $0.name.contains("wine-crossover") && $0.name.hasSuffix(".tar.xz") }
            ?? release.assets.first { $0.name.contains("wine") && $0.name.hasSuffix(".tar.xz") }

        guard let asset else {
            throw BarrelError.noWineBuildFound
        }

        return WineBuild(version: release.tagName, downloadURL: asset.browserDownloadURL, arch: "arm64")
    }

    func downloadWine(_ build: WineBuild, progress: @escaping (Double) -> Void) async throws {
        let destination = StorageManager.shared.wineDirectory.appending(path: "wine-\(build.version).tar.xz")

        let (tempURL, response) = try await URLSession.shared.download(from: build.downloadURL)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw BarrelError.downloadFailed
        }

        try FileManager.default.moveItem(at: tempURL, to: destination)
        try await extractWine(archive: destination, version: build.version)
        try FileManager.default.removeItem(at: destination)
    }

    private func extractWine(archive: URL, version: String) async throws {
        let outputDir = StorageManager.shared.wineDirectory.appending(path: "wine-\(version)")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/tar")
        process.arguments = ["-xJf", archive.path, "-C", outputDir.path, "--strip-components=1"]
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw BarrelError.extractionFailed
        }
    }
}

// MARK: - GitHub API models

private struct GithubRelease: Decodable {
    let tagName: String
    let assets: [GithubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case assets
    }
}

private struct GithubAsset: Decodable {
    let name: String
    let browserDownloadURL: URL

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}

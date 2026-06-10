import Foundation

actor DownloadService {
    static let shared = DownloadService()

    private let gcenxReleasesURL = URL(string: "https://api.github.com/repos/Gcenx/macOS_Wine_builds/releases/latest")!

    func latestWineBuild() async throws -> WineBuild {
        var request = URLRequest(url: gcenxReleasesURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Barrel/1.0 macOS", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw BarrelError.downloadFailed
        }
        let release = try JSONDecoder().decode(GithubRelease.self, from: data)

        // Prefer wine-staging (better game compat) → wine-devel → any .tar.xz
        let asset = release.assets.first { $0.name.contains("wine-staging") && $0.name.hasSuffix(".tar.xz") }
            ?? release.assets.first { $0.name.contains("wine-devel") && $0.name.hasSuffix(".tar.xz") }
            ?? release.assets.first { $0.name.contains("wine") && $0.name.hasSuffix(".tar.xz") }

        guard let asset else { throw BarrelError.noWineBuildFound }

        return WineBuild(version: release.tagName, downloadURL: asset.browserDownloadURL, arch: "x86_64")
    }

    func downloadWine(_ build: WineBuild, progress: @escaping @Sendable (Double) -> Void) async throws {
        let archiveName = "wine-\(build.version).tar.xz"
        let destination = StorageManager.shared.wineDirectory.appending(path: archiveName)

        var request = URLRequest(url: build.downloadURL)
        request.setValue("Barrel/1.0 macOS", forHTTPHeaderField: "User-Agent")

        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw BarrelError.downloadFailed
        }

        let totalBytes = response.expectedContentLength
        FileManager.default.createFile(atPath: destination.path, contents: nil)
        let handle = try FileHandle(forWritingTo: destination)

        var buffer = Data(capacity: 512 * 1024)
        var receivedBytes: Int64 = 0

        for try await byte in asyncBytes {
            buffer.append(byte)
            receivedBytes += 1
            if buffer.count >= 512 * 1024 {
                try handle.write(contentsOf: buffer)
                buffer.removeAll(keepingCapacity: true)
                if totalBytes > 0 {
                    progress(0.8 * Double(receivedBytes) / Double(totalBytes))
                }
            }
        }
        if !buffer.isEmpty { try handle.write(contentsOf: buffer) }
        try handle.close()
        progress(0.82)

        try await extractWine(archive: destination, version: build.version)
        try? FileManager.default.removeItem(at: destination)
        progress(1.0)
    }

    private func extractWine(archive: URL, version: String) async throws {
        let outputDir = StorageManager.shared.wineDirectory.appending(path: "wine-\(version)")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/tar")
        process.arguments = ["-xJf", archive.path, "-C", outputDir.path, "--strip-components=1"]
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else { throw BarrelError.extractionFailed }
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

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

        let tempURL = try await downloadFile(from: build.downloadURL) { p in
            progress(0.8 * p)
        }
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: tempURL, to: destination)
        progress(0.82)

        try await extractWine(archive: destination, version: build.version)
        try? FileManager.default.removeItem(at: destination)
        progress(1.0)
    }

    /// Downloads a file via URLSessionDownloadTask (real streaming, no per-byte overhead)
    /// and reports progress. Returns a temporary file URL — caller is responsible for
    /// moving it to its final destination.
    func downloadFile(
        from url: URL,
        userAgent: String = "Barrel/1.0 macOS",
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        return try await withCheckedThrowingContinuation { continuation in
            let delegate = ProgressDownloadDelegate(progress: progress, continuation: continuation)
            let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
            session.downloadTask(with: request).resume()
        }
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

// MARK: - Download progress delegate

/// Bridges URLSessionDownloadTask's delegate callbacks to async/await with real
/// progress reporting, avoiding the per-byte overhead of AsyncBytes iteration.
private final class ProgressDownloadDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let progress: @Sendable (Double) -> Void
    private var continuation: CheckedContinuation<URL, Error>?
    private let lock = NSLock()

    init(progress: @escaping @Sendable (Double) -> Void, continuation: CheckedContinuation<URL, Error>) {
        self.progress = progress
        self.continuation = continuation
    }

    private func resume(_ result: Result<URL, Error>) {
        lock.lock()
        let cont = continuation
        continuation = nil
        lock.unlock()
        guard let cont else { return }
        switch result {
        case .success(let url): cont.resume(returning: url)
        case .failure(let error): cont.resume(throwing: error)
        }
    }

    func urlSession(
        _ session: URLSession, downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        progress(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let dest = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.moveItem(at: location, to: dest)
            resume(.success(dest))
        } catch {
            resume(.failure(error))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error { resume(.failure(error)) }
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

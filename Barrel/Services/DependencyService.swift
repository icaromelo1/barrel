import Foundation

actor DependencyService {
    static let shared = DependencyService()

    // MARK: - Instalação via Winetricks

    func install(_ dependency: Dependency, in bottle: Bottle) async throws -> AsyncStream<LogEntry> {
        guard let verb = dependency.winetricksVerb else {
            return try await installManual(dependency, in: bottle)
        }
        return try runWinetricks(verb: verb, in: bottle)
    }

    private func runWinetricks(verb: String, in bottle: Bottle) throws -> AsyncStream<LogEntry> {
        guard let winetricksPath = findWinetricks() else {
            throw DependencyError.winetricksNotFound
        }

        let process = Process()
        process.executableURL = URL(filePath: winetricksPath)
        process.arguments = ["-q", verb]
        process.environment = ProcessInfo.processInfo.environment.merging([
            "WINEPREFIX": bottle.prefixURL.path,
            "WINEDEBUG": "-all"
        ]) { _, new in new }

        let pipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errPipe

        let stream = AsyncStream<LogEntry> { continuation in
            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let line = String(data: data, encoding: .utf8) else { return }
                continuation.yield(LogEntry(level: .info, message: line.trimmingCharacters(in: .newlines)))
            }
            errPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty, let line = String(data: data, encoding: .utf8) else { return }
                continuation.yield(LogEntry(level: .warning, message: line.trimmingCharacters(in: .newlines)))
            }
            process.terminationHandler = { _ in
                pipe.fileHandleForReading.readabilityHandler = nil
                errPipe.fileHandleForReading.readabilityHandler = nil
                continuation.finish()
            }
        }

        try process.run()
        return stream
    }

    // MARK: - Instalação manual (DXVK, VKD3D)

    private func installManual(_ dependency: Dependency, in bottle: Bottle) async throws -> AsyncStream<LogEntry> {
        switch dependency.id {
        case "dxvk":
            return try await installDXVK(in: bottle)
        default:
            throw DependencyError.unsupported(dependency.id)
        }
    }

    private func installDXVK(in bottle: Bottle) async throws -> AsyncStream<LogEntry> {
        return AsyncStream { continuation in
            Task {
                continuation.yield(LogEntry(level: .info, message: "Baixando DXVK..."))
                do {
                    let release = try await fetchLatestDXVK()
                    let archive = try await downloadDXVK(release)
                    try installDXVKDLLs(from: archive, into: bottle)
                    try await applyDXVKRegistryOverrides(in: bottle)
                    continuation.yield(LogEntry(level: .info, message: "DXVK instalado com sucesso."))
                } catch {
                    continuation.yield(LogEntry(level: .error, message: "Erro ao instalar DXVK: \(error.localizedDescription)"))
                }
                continuation.finish()
            }
        }
    }

    private func fetchLatestDXVK() async throws -> String {
        let url = URL(string: "https://api.github.com/repos/doitsujin/dxvk/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let tagName = json?["tag_name"] as? String else { throw DependencyError.fetchFailed }
        return tagName
    }

    private func downloadDXVK(_ version: String) async throws -> URL {
        let name = "dxvk-\(version.replacingOccurrences(of: "v", with: "")).tar.gz"
        let url = URL(string: "https://github.com/doitsujin/dxvk/releases/download/\(version)/\(name)")!
        let dest = StorageManager.shared.cacheDirectory.appending(path: name)
        let (tempURL, _) = try await URLSession.shared.download(from: url)
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.moveItem(at: tempURL, to: dest)
        return dest
    }

    private func installDXVKDLLs(from archive: URL, into bottle: Bottle) throws {
        let extractDir = StorageManager.shared.cacheDirectory.appending(path: "dxvk-extract")
        try? FileManager.default.removeItem(at: extractDir)
        try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)

        let tar = Process()
        tar.executableURL = URL(filePath: "/usr/bin/tar")
        tar.arguments = ["-xzf", archive.path, "-C", extractDir.path, "--strip-components=1"]
        try tar.run()
        tar.waitUntilExit()

        let dlls = ["d3d9.dll", "d3d10core.dll", "d3d11.dll", "dxgi.dll"]
        let system32 = bottle.prefixURL.appending(path: "drive_c/windows/system32")
        let syswow64 = bottle.prefixURL.appending(path: "drive_c/windows/syswow64")

        for dll in dlls {
            let x64 = extractDir.appending(path: "x64/\(dll)")
            let x32 = extractDir.appending(path: "x32/\(dll)")
            if FileManager.default.fileExists(atPath: x64.path) {
                try? FileManager.default.removeItem(at: system32.appending(path: dll))
                try FileManager.default.copyItem(at: x64, to: system32.appending(path: dll))
            }
            if FileManager.default.fileExists(atPath: x32.path) {
                try? FileManager.default.removeItem(at: syswow64.appending(path: dll))
                try FileManager.default.copyItem(at: x32, to: syswow64.appending(path: dll))
            }
        }
    }

    private func applyDXVKRegistryOverrides(in bottle: Bottle) async throws {
        let dlls = ["d3d9", "d3d10core", "d3d11", "dxgi"]
        for dll in dlls {
            try await WineService.shared.setRegistryValue(
                key: "HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides",
                name: dll,
                type: "REG_SZ",
                value: "native,builtin",
                in: bottle.prefixURL
            )
        }
    }

    // MARK: - Utils

    private func findWinetricks() -> String? {
        let candidates = ["/opt/homebrew/bin/winetricks", "/usr/local/bin/winetricks"]
        return candidates.first { FileManager.default.fileExists(atPath: $0) }
    }
}

enum DependencyError: LocalizedError {
    case winetricksNotFound
    case fetchFailed
    case unsupported(String)

    var errorDescription: String? {
        switch self {
        case .winetricksNotFound:  return "Winetricks não encontrado. Instale com: brew install winetricks"
        case .fetchFailed:         return "Falha ao buscar versão mais recente."
        case .unsupported(let id): return "Instalação manual não suportada para: \(id)"
        }
    }
}

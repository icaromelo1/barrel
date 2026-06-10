import Foundation

actor WineService {
    static let shared = WineService()

    private var activeBuild: WineBuild?

    func setActiveBuild(_ build: WineBuild) {
        self.activeBuild = build
    }

    // MARK: - Execução principal

    /// Executa um binário Wine e retorna stream de logs em tempo real.
    func run(
        args: [String],
        prefix: URL,
        extraEnv: [String: String] = [:]
    ) throws -> (process: Process, logStream: AsyncStream<LogEntry>) {
        let build = try requireActiveBuild()

        let process = Process()
        process.executableURL = build.wineBinary
        process.arguments = args
        process.environment = buildEnvironment(prefix: prefix, extra: extraEnv)

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
                continuation.yield(LogEntry(level: .error, message: line.trimmingCharacters(in: .newlines)))
            }
            process.terminationHandler = { _ in
                pipe.fileHandleForReading.readabilityHandler = nil
                errPipe.fileHandleForReading.readabilityHandler = nil
                continuation.finish()
            }
        }

        try process.run()
        return (process, stream)
    }

    // MARK: - Operações de garrafa

    func bootPrefix(_ prefix: URL) async throws {
        let (process, stream) = try run(args: ["wineboot", "--init"], prefix: prefix)
        for await _ in stream {}
        guard process.terminationStatus == 0 else {
            throw BarrelError.wineBootFailed
        }
    }

    func runInstaller(at path: String, in prefix: URL) throws -> (Process, AsyncStream<LogEntry>) {
        try run(args: [path], prefix: prefix)
    }

    func runExecutable(_ path: String, in prefix: URL, args: [String] = []) throws -> (Process, AsyncStream<LogEntry>) {
        try run(args: [path] + args, prefix: prefix)
    }

    // MARK: - Registry

    func setRegistryValue(key: String, name: String, type: String, value: String, in prefix: URL) async throws {
        let (process, stream) = try run(
            args: ["reg", "add", key, "/v", name, "/t", type, "/d", value, "/f"],
            prefix: prefix
        )
        for await _ in stream {}
        guard process.terminationStatus == 0 else {
            throw BarrelError.registryWriteFailed
        }
    }

    // MARK: - Helpers

    private func requireActiveBuild() throws -> WineBuild {
        guard let build = activeBuild else { throw BarrelError.noWineInstalled }
        guard build.isInstalled else { throw BarrelError.noWineInstalled }
        return build
    }

    private func buildEnvironment(prefix: URL, extra: [String: String]) -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        env["WINEPREFIX"] = prefix.path
        env["WINEDEBUG"] = "-all"           // silencia logs verbose do Wine
        env["WINEDLLOVERRIDES"] = "winemenubuilder.exe=d"
        env["WINE_LARGE_ADDRESS_AWARE"] = "1"
        for (key, value) in extra { env[key] = value }
        return env
    }
}

// MARK: - Log

struct LogEntry: Identifiable {
    let id = UUID()
    let level: LogLevel
    let message: String
    let timestamp = Date()
}

enum LogLevel {
    case info, warning, error
}

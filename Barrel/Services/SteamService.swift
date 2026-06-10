import Foundation

/// Handles Steam-specific setup inside a Wine prefix.
actor SteamService {
    static let shared = SteamService()

    private let fm = FileManager.default

    // Relative path inside drive_c where steamwebhelper lives
    private let cefDir = "Program Files (x86)/Steam/bin/cef/cef.win64"
    private let wrapperResource = "steamwebhelper_wrapper"
    private let wrapperExt = "exe"

    // MARK: - Public

    /// Installs the no-sandbox wrapper into the bottle's Steam CEF directory.
    /// Safe to call multiple times — idempotent.
    func installWrapper(in prefix: URL) throws {
        let cefURL = prefix.appending(path: "drive_c").appending(path: cefDir)

        guard fm.fileExists(atPath: cefURL.path) else { return } // Steam not installed here

        let realHelper  = cefURL.appending(path: "steamwebhelper_real.exe")
        let fakeHelper  = cefURL.appending(path: "steamwebhelper.exe")

        // Step 1 — locate the bundled wrapper .exe
        guard let wrapperSrc = Bundle.main.url(
            forResource: wrapperResource, withExtension: wrapperExt
        ) else {
            throw SteamError.wrapperResourceMissing
        }

        // Step 2 — if no backup yet, rename the real helper
        if !fm.fileExists(atPath: realHelper.path) {
            guard fm.fileExists(atPath: fakeHelper.path) else { return } // nothing to wrap
            try fm.moveItem(at: fakeHelper, to: realHelper)
        }

        // Step 3 — copy (or overwrite) wrapper as steamwebhelper.exe
        if fm.fileExists(atPath: fakeHelper.path) {
            try fm.removeItem(at: fakeHelper)
        }
        try fm.copyItem(at: wrapperSrc, to: fakeHelper)

        // Step 4 — write steam.cfg to block auto-update overwriting the wrapper
        writeSteamCfg(in: prefix)
    }

    /// Checks whether the wrapper is already installed.
    func isWrapperInstalled(in prefix: URL) -> Bool {
        let real = prefix
            .appending(path: "drive_c")
            .appending(path: cefDir)
            .appending(path: "steamwebhelper_real.exe")
        return fm.fileExists(atPath: real.path)
    }

    // MARK: - Private

    private func writeSteamCfg(in prefix: URL) {
        let steamDir = prefix.appending(path: "drive_c/Program Files (x86)/Steam")
        let cfg = steamDir.appending(path: "steam.cfg")
        // Prevents bootstrapper from re-downloading and overwriting our wrapper
        let content = "BootStrapperInhibitAll=Enable\n"
        try? content.write(to: cfg, atomically: true, encoding: .utf8)
    }
}

enum SteamError: LocalizedError {
    case wrapperResourceMissing

    var errorDescription: String? {
        switch self {
        case .wrapperResourceMissing:
            return "steamwebhelper_wrapper.exe não encontrado no bundle do app."
        }
    }
}

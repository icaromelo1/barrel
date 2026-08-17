import SwiftUI

@MainActor
final class WineSetupViewModel: ObservableObject {
    @Published var state: SetupState = .idle
    @Published var progressMessage = ""
    @Published var downloadProgress: Double = 0

    enum SetupState: Equatable {
        case idle, checking, downloading, extracting, ready, failed(String)

        var isReady: Bool {
            if case .ready = self { return true }
            return false
        }

        var isInProgress: Bool {
            switch self {
            case .checking, .downloading, .extracting: return true
            default: return false
            }
        }

        static func == (lhs: SetupState, rhs: SetupState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.checking, .checking),
                 (.downloading, .downloading), (.extracting, .extracting),
                 (.ready, .ready): return true
            case (.failed(let a), .failed(let b)): return a == b
            default: return false
            }
        }
    }

    func setup() async {
        guard state == .idle || state == .failed("") else { return }
        state = .checking
        downloadProgress = 0
        progressMessage = "Verificando Wine..."

        do {
            if let local = findLocalBuild() {
                await WineService.shared.setActiveBuild(local)
                progressMessage = "Wine \(local.version) pronto."
                state = .ready
                return
            }

            state = .downloading
            progressMessage = "Buscando versão mais recente..."
            let build = try await DownloadService.shared.latestWineBuild()

            progressMessage = "Baixando Wine \(build.version)..."
            try await DownloadService.shared.downloadWine(build) { [weak self] p in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if p > 0.81 {
                        self.state = .extracting
                        self.progressMessage = "Extraindo Wine..."
                    }
                    self.downloadProgress = p
                }
            }

            await WineService.shared.setActiveBuild(build)
            progressMessage = "Wine \(build.version) pronto."
            downloadProgress = 1.0
            state = .ready

        } catch {
            state = .failed(error.localizedDescription)
            progressMessage = error.localizedDescription
        }
    }

    func retry() async {
        state = .idle
        await setup()
    }

    private func findLocalBuild() -> WineBuild? {
        let dir = StorageManager.shared.wineDirectory
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil
        ) else { return nil }

        return contents.compactMap { url -> WineBuild? in
            let version = url.lastPathComponent.replacingOccurrences(of: "wine-", with: "")
            // Search for the real wine binary instead of assuming a fixed release layout.
            guard WineBuild.findBinDirectory(named: "wine", under: url) != nil else { return nil }
            return WineBuild(
                version: version,
                downloadURL: URL(string: "file://local")!,
                arch: "x86_64"
            )
        }.first
    }
}

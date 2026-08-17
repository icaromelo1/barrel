import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var games: [Game] = []
    @Published var isLoading = false
    @Published var error: String?

    func load() async {
        do {
            games = try await GameService.shared.loadAll()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func appendGame(_ game: Game) {
        guard !games.contains(where: { $0.id == game.id }) else { return }
        games.append(game)
    }

    func addGame(name: String, exePath: String, bottleId: UUID) async -> Game? {
        do {
            let game = try await GameService.shared.add(
                name: name,
                exePath: exePath,
                bottleId: bottleId
            )
            games.append(game)
            return game
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    func remove(_ game: Game) async {
        do {
            try await GameService.shared.remove(id: game.id)
            games.removeAll { $0.id == game.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - File picker

    @discardableResult
    func pickExeFile(startingAt directory: URL? = nil) async -> URL? {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let panel = NSOpenPanel()
                panel.title = "Selecionar executável do jogo"
                panel.allowedContentTypes = [UTType(filenameExtension: "exe") ?? .data]
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                if let directory { panel.directoryURL = directory }
                if panel.runModal() == .OK {
                    continuation.resume(returning: panel.url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

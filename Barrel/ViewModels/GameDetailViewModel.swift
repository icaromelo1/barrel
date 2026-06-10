import SwiftUI

@MainActor
final class GameDetailViewModel: ObservableObject {
    @Published var logs: [LogEntry] = []
    @Published var isRunning = false
    @Published var error: String?

    private var activeProcess: Process?

    func launch(_ game: Game, in bottle: Bottle) async {
        guard !isRunning else { return }
        isRunning = true
        logs = []

        do {
            let (process, stream) = try await WineService.shared.runExecutable(
                game.exePath,
                in: bottle.prefixURL,
                args: game.launchArgs.components(separatedBy: " ").filter { !$0.isEmpty }
            )
            activeProcess = process
            for await entry in stream {
                logs.append(entry)
            }
        } catch {
            logs.append(LogEntry(level: .error, message: error.localizedDescription))
        }

        isRunning = false
        activeProcess = nil
    }

    func stop() {
        activeProcess?.terminate()
    }
}

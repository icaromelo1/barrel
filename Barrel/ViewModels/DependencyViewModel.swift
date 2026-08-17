import SwiftUI

@MainActor
final class DependencyViewModel: ObservableObject {
    @Published var installingId: String?
    @Published var installProgress: Int = 0
    @Published var logs: [LogEntry] = []
    @Published var error: String?

    private var bottle: Bottle?
    private var installedIds: Set<String> = []

    /// Loads which dependencies are already installed from the bottle's persisted
    /// state — call this once the real `Bottle` is known (e.g. in `.onAppear`).
    func load(from bottle: Bottle) {
        self.bottle = bottle
        self.installedIds = Set(bottle.installedDependencyIds)
    }

    func isInstalled(_ dep: Dependency) -> Bool {
        installedIds.contains(dep.id)
    }

    func install(_ dep: Dependency, into bottle: Bottle) async {
        guard installingId == nil else { return }
        installingId = dep.id
        logs = []

        do {
            let stream = try await DependencyService.shared.install(dep, in: bottle)
            for await entry in stream {
                logs.append(entry)
            }
            installedIds.insert(dep.id)
            await persist(depId: dep.id, fallback: bottle)
        } catch {
            self.error = error.localizedDescription
        }

        installingId = nil
    }

    /// Persists the newly-installed dependency id onto the bottle so it survives
    /// app restarts. Uses the locally-tracked bottle if `load(from:)` was called,
    /// falling back to whatever was passed into `install(_:into:)`.
    private func persist(depId: String, fallback: Bottle) async {
        var updated = bottle ?? fallback
        if !updated.installedDependencyIds.contains(depId) {
            updated.installedDependencyIds.append(depId)
        }
        bottle = updated
        try? await BottleService.shared.update(updated)
    }
}

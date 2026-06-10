import SwiftUI

@MainActor
final class DependencyViewModel: ObservableObject {
    @Published var installingId: String?
    @Published var installProgress: Int = 0
    @Published var logs: [LogEntry] = []
    @Published var error: String?

    private var installedIds: Set<String> = []

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
        } catch {
            self.error = error.localizedDescription
        }

        installingId = nil
    }
}

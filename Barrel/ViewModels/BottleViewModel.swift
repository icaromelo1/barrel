import SwiftUI

@MainActor
final class BottleViewModel: ObservableObject {
    @Published var bottles: [Bottle] = []
    @Published var isLoading = false
    @Published var error: String?
    /// Live status message per bottle while initializing (transient, not persisted)
    @Published var initMessages: [UUID: String] = [:]

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            bottles = try await BottleService.shared.loadAll()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createWithPreset(name: String, config: BottleConfig, preset: BottlePreset) async -> Bottle? {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Nome não pode ser vazio."
            return nil
        }
        isLoading = true
        do {
            var bottle = try await BottleService.shared.create(name: name, config: config, preset: preset)
            bottles.append(bottle)
            isLoading = false

            // Initialize in background: wineboot → deps
            initMessages[bottle.id] = "Iniciando Wine..."
            Task.detached(priority: .userInitiated) { [weak self] in
                guard let self else { return }

                do {
                    // Step 1: wineboot --init
                    try await WineService.shared.bootPrefix(bottle.prefixURL)
                } catch {
                    await MainActor.run {
                        self.initMessages[bottle.id] = "Erro no wineboot: \(error.localizedDescription)"
                    }
                    await self.markBottle(bottle.id, status: .failed)
                    return
                }

                // Step 2: preset deps
                await DependencyService.shared.installForPreset(preset, in: bottle) { msg in
                    await MainActor.run { self.initMessages[bottle.id] = msg }
                }

                // Step 3: mark ready
                bottle.initStatus = .ready
                try? await BottleService.shared.update(bottle)
                await MainActor.run {
                    self.initMessages.removeValue(forKey: bottle.id)
                    if let idx = self.bottles.firstIndex(where: { $0.id == bottle.id }) {
                        self.bottles[idx].initStatus = .ready
                    }
                }
            }

            return bottle
        } catch {
            isLoading = false
            self.error = error.localizedDescription
            return nil
        }
    }

    func delete(_ bottle: Bottle) async {
        do {
            try await BottleService.shared.delete(bottle)
            bottles.removeAll { $0.id == bottle.id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func markBottle(_ id: UUID, status: BottleInitStatus) async {
        if let idx = bottles.firstIndex(where: { $0.id == id }) {
            bottles[idx].initStatus = status
        }
    }
}

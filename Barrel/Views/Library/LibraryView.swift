import SwiftUI

struct LibraryView: View {
    @Binding var selectedBottle: String?
    @ObservedObject var libraryVM: LibraryViewModel
    @ObservedObject var bottleVM: BottleViewModel
    @State private var showInstallApp = false
    @State private var runningGames: Set<UUID> = []
    @State private var gameToDelete: Game? = nil

    var selectedBottleObj: Bottle? {
        guard let id = selectedBottle, let uuid = UUID(uuidString: id) else { return nil }
        return bottleVM.bottles.first { $0.id == uuid }
    }

    var title: String { selectedBottleObj?.name ?? "All Games" }

    var displayGames: [GameData] {
        let filtered = selectedBottle == nil
            ? libraryVM.games
            : libraryVM.games.filter { $0.bottleId.uuidString == selectedBottle }
        return filtered.map { game in
            let bottle = bottleVM.bottles.first { $0.id == game.bottleId }
            return GameData.from(game, bottle: bottle)
        }
    }

    var body: some View {
        Group {
            if displayGames.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(displayGames.count) title\(displayGames.count == 1 ? "" : "s") · \(bottleVM.bottles.count) bottle\(bottleVM.bottles.count == 1 ? "" : "s")")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.t3)
                            .padding(.bottom, 20)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 22), count: 5),
                            spacing: 22
                        ) {
                            ForEach(displayGames) { gameData in
                                let gameUUID = UUID(uuidString: gameData.id)
                                let isRunning = gameUUID.map { runningGames.contains($0) } ?? false
                                GameCardView(
                                    game: gameData,
                                    isRunning: isRunning,
                                    onLaunch: { launch(gameData) }
                                )
                                .contextMenu {
                                    if isRunning {
                                        Label("Running…", systemImage: "play.circle.fill")
                                            .foregroundStyle(Color.statusGreen)
                                    } else {
                                        Button {
                                            launch(gameData)
                                        } label: {
                                            Label("Launch", systemImage: "play.fill")
                                        }
                                    }
                                    Divider()
                                    Button(role: .destructive) {
                                        if let uuid = gameUUID {
                                            gameToDelete = libraryVM.games.first { $0.id == uuid }
                                        }
                                    } label: {
                                        Label("Remove from Library", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(26)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                WallpaperView()
                Color.contentBg.opacity(0.6)
            }
            .ignoresSafeArea()
        )
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showInstallApp = true }) {
                    Label("Install App", systemImage: "arrow.down.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#8b6bff"))
                .disabled(bottleVM.bottles.isEmpty)
            }
        }
        .sheet(isPresented: $showInstallApp) {
            InstallAppSheet(isPresented: $showInstallApp, bottleVM: bottleVM, libraryVM: libraryVM)
        }
        .confirmationDialog(
            "Remove \"\(gameToDelete?.name ?? "")\" from the library?",
            isPresented: Binding(get: { gameToDelete != nil }, set: { if !$0 { gameToDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let game = gameToDelete {
                    Task { await libraryVM.remove(game) }
                }
                gameToDelete = nil
            }
            Button("Cancel", role: .cancel) { gameToDelete = nil }
        } message: {
            Text("The app files inside the bottle are not deleted.")
        }
    }

    // MARK: - Launch

    private func launch(_ gameData: GameData) {
        guard let gameUUID = UUID(uuidString: gameData.id) else { return }
        guard !runningGames.contains(gameUUID) else { return }
        guard let game = libraryVM.games.first(where: { $0.id == gameUUID }),
              let bottle = bottleVM.bottles.first(where: { $0.id == game.bottleId }) else { return }

        // Windows paths use \, URL(fileURLWithPath:) doesn't treat \ as separator on macOS
        let exeName = (game.exePath.components(separatedBy: "\\").last ?? game.exePath).lowercased()

        runningGames.insert(gameUUID)
        Task {
            do {
                try? await SteamService.shared.installWrapper(in: bottle.prefixURL)
                let args = game.launchArgs.isEmpty ? [] : game.launchArgs.components(separatedBy: " ")
                let (_, stream) = try await WineService.shared.runExecutable(
                    game.exePath, in: bottle.prefixURL, args: args
                )
                Task.detached { for await _ in stream {} }
                await monitorUntilExit(exeName: exeName)
            } catch {}
            await MainActor.run { runningGames.remove(gameUUID) }
        }
    }

    /// Phase 1: waits up to 15s for the exe to appear in ps (Steam re-spawns itself).
    /// Phase 2: polls every 3s until no matching process remains.
    private func monitorUntilExit(exeName: String) async {
        var appeared = false
        for _ in 0..<5 {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if isWineProcessRunning(exeName: exeName) { appeared = true; break }
        }
        guard appeared else { return }
        for _ in 0..<100 {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if !isWineProcessRunning(exeName: exeName) { return }
        }
    }

    private func isWineProcessRunning(exeName: String) -> Bool {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/ps")
        p.arguments = ["aux"]
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = FileHandle.nullDevice
        try? p.run()
        p.waitUntilExit()
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return out.lowercased().contains(exeName)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyIcon)
                .font(.system(size: 44))
                .foregroundStyle(Color.t4)

            Text(emptyTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.t2)

            Text(emptySubtitle)
                .font(.system(size: 13))
                .foregroundStyle(Color.t3)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            if !bottleVM.bottles.isEmpty {
                Button(action: { showInstallApp = true }) {
                    Label(emptyCTA, systemImage: "arrow.down.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 9)
                        .background(LinearGradient.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .shadow(color: Color(hex: "#7c5cff").opacity(0.4), radius: 8, y: 2)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyIcon: String {
        if selectedBottleObj?.preset == .steam { return "gamecontroller" }
        if selectedBottle != nil { return "tray" }
        return "square.grid.2x2"
    }

    private var emptyTitle: String {
        if let bottle = selectedBottleObj {
            switch bottle.preset {
            case .steam:         return "Steam not installed"
            case .gaming:        return "No apps installed"
            case .compatibility: return "No apps installed"
            case nil:            return "No apps installed"
            }
        }
        if bottleVM.bottles.isEmpty { return "No bottles yet" }
        return "Library is empty"
    }

    private var emptySubtitle: String {
        if let bottle = selectedBottleObj {
            switch bottle.preset {
            case .steam:         return "Install Steam to access your library and play games through this bottle."
            case .gaming:        return "Use \"Install App\" to run a Windows installer inside this bottle."
            case .compatibility: return "Use \"Install App\" to run a Windows installer inside this bottle."
            case nil:            return "Use \"Install App\" to run a Windows installer inside this bottle."
            }
        }
        if bottleVM.bottles.isEmpty { return "Create a bottle first using the sidebar, then install apps inside it." }
        return "Select a bottle and install apps to see them here."
    }

    private var emptyCTA: String {
        selectedBottleObj?.preset == .steam ? "Install Steam" : "Install App"
    }
}

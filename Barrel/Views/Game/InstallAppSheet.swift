import SwiftUI
import UniformTypeIdentifiers

// MARK: - Known App catalog

struct KnownApp: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let accentHex: String
    let tagline: String
    let installerURL: String
    let defaultExeRelativePath: String
    var defaultLaunchArgs: String = ""

    static let catalog: [KnownApp] = [
        KnownApp(
            id: "steam",
            name: "Steam",
            symbol: "gamecontroller.fill",
            accentHex: "#4a90d9",
            tagline: "Play your entire Steam library",
            installerURL: "https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe",
            defaultExeRelativePath: "Program Files (x86)/Steam/steam.exe",
            defaultLaunchArgs: "-no-cef-sandbox"
        ),
        KnownApp(
            id: "epic",
            name: "Epic Games",
            symbol: "bolt.fill",
            accentHex: "#ffffff",
            tagline: "Epic Games Store & launcher",
            installerURL: "https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi",
            defaultExeRelativePath: "Program Files (x86)/Epic Games/Launcher/Portal/Binaries/Win32/EpicGamesLauncher.exe"
        ),
        KnownApp(
            id: "gog",
            name: "GOG Galaxy",
            symbol: "star.fill",
            accentHex: "#a76bff",
            tagline: "DRM-free game collection",
            installerURL: "https://cdn.gog.com/open/galaxy/client/2.0/setup_galaxy_2.0.72.12.exe",
            defaultExeRelativePath: "Program Files (x86)/GOG Galaxy/GalaxyClient.exe"
        ),
        KnownApp(
            id: "battlenet",
            name: "Battle.net",
            symbol: "shield.fill",
            accentHex: "#148eff",
            tagline: "Blizzard & Activision titles",
            installerURL: "https://www.battle.net/download/getInstallerForGame?os=win&locale=enUS&version=LIVE&gameProgram=BATTLENET_APP",
            defaultExeRelativePath: "Program Files (x86)/Battle.net/Battle.net.exe"
        ),
    ]
}

// MARK: - Sheet

struct InstallAppSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var bottleVM: BottleViewModel
    @ObservedObject var libraryVM: LibraryViewModel

    @State private var selectedBottleId: UUID?
    @State private var selectedApp: KnownApp?
    @State private var isCustom = false
    @State private var customInstallerPath = ""
    @State private var customAppName = ""
    @State private var isPicking = false
    @State private var isInstalling = false
    @State private var installProgress: Double = 0
    @State private var installStatus = ""
    @State private var installError: String?
    @State private var installerRunning = false  // Wine installer window is open

    private var selectedBottle: Bottle? {
        bottleVM.bottles.first { $0.id == selectedBottleId }
    }

    private var isAlreadyInstalled: Bool {
        guard let app = selectedApp,
              let bottle = selectedBottle else { return false }
        let exeURL = bottle.prefixURL
            .appending(path: "drive_c")
            .appending(path: app.defaultExeRelativePath)
        return FileManager.default.fileExists(atPath: exeURL.path)
    }

    private var canInstall: Bool {
        guard selectedBottleId != nil else { return false }
        if isAlreadyInstalled { return false }
        return selectedApp != nil || (isCustom && !customInstallerPath.isEmpty)
    }

    private var installLabel: String {
        if isAlreadyInstalled { return "Already Installed" }
        if let app = selectedApp { return "Install \(app.name)" }
        if isCustom && !customInstallerPath.isEmpty { return "Run Installer" }
        return "Install"
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    Text("Install App")
                        .font(.system(size: 19, weight: .bold))
                        .tracking(-0.4)
                        .foregroundStyle(Color.t1)
                    Text("Download and install a Windows application into a bottle.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.t2)
                        .padding(.top, 4)

                    // Bottle selector
                    Text("Bottle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.t2)
                        .padding(.top, 22)
                        .padding(.bottom, 8)

                    if bottleVM.bottles.isEmpty {
                        emptyBottlesWarning
                    } else {
                        bottlePicker
                    }

                    // App catalog
                    if !installerRunning {
                        Text("Choose Application")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.t2)
                            .padding(.top, 22)
                            .padding(.bottom, 10)

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(KnownApp.catalog) { app in
                                AppCatalogCard(app: app, selected: selectedApp?.id == app.id && !isCustom)
                                    .onTapGesture {
                                        selectedApp = app
                                        isCustom = false
                                    }
                            }
                            CustomInstallerCard(selected: isCustom)
                                .onTapGesture {
                                    isCustom = true
                                    selectedApp = nil
                                }
                        }

                        if isCustom {
                            customInstallerSection
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    // Progress / status
                    if isInstalling || installerRunning {
                        installStatusView
                            .padding(.top, 18)
                    }

                    // Error
                    if let err = installError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.statusRed)
                            Text(err)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.statusRed)
                        }
                        .padding(.top, 10)
                    }
                }
                .padding(28)
            }

            // Footer
            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.t1)
                    .frame(height: 32)
                    .padding(.horizontal, 16)
                    .background(Color.white.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.stroke2, lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .buttonStyle(.plain)
                    .disabled(isInstalling)

                if !installerRunning {
                    Button(action: startInstall) {
                        HStack(spacing: 7) {
                            if isInstalling {
                                ProgressView().progressViewStyle(.circular).scaleEffect(0.7).tint(.white)
                                Text("Downloading…")
                            } else if isAlreadyInstalled {
                                Image(systemName: "checkmark.circle.fill").font(.system(size: 12, weight: .semibold))
                                Text(installLabel)
                            } else {
                                Image(systemName: "arrow.down.circle.fill").font(.system(size: 12, weight: .semibold))
                                Text(installLabel)
                            }
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isAlreadyInstalled ? Color.t3 : .white)
                        .frame(height: 32)
                        .padding(.horizontal, 18)
                        .background(canInstall ? LinearGradient.accent : LinearGradient(colors: [Color.white.opacity(0.15)], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: canInstall ? Color(hex: "#7c5cff").opacity(0.4) : .clear, radius: 8, y: 2)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canInstall || isInstalling)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(Color.black.opacity(0.22))
            .overlay(alignment: .top) { Rectangle().fill(Color.stroke).frame(height: 0.5) }
        }
        .background(Color(hex: "#2c2c30").opacity(0.9).background(.ultraThickMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stroke2, lineWidth: 0.5))
        .frame(width: 520)
        .shadow(color: .black.opacity(0.6), radius: 70, y: 30)
        .animation(.easeInOut(duration: 0.2), value: isCustom)
        .animation(.easeInOut(duration: 0.2), value: isInstalling)
        .onAppear { selectedBottleId = bottleVM.bottles.first?.id }
    }

    // MARK: - Subviews

    private var emptyBottlesWarning: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundStyle(Color.statusAmber)
            Text("No bottles yet. Create a bottle first from the sidebar.")
                .font(.system(size: 13))
                .foregroundStyle(Color.t2)
        }
        .padding(12)
        .background(Color.statusAmber.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.statusAmber.opacity(0.25), lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var bottlePicker: some View {
        VStack(spacing: 6) {
            ForEach(bottleVM.bottles) { bottle in
                let sel = selectedBottleId == bottle.id
                HStack(spacing: 10) {
                    Image(systemName: "flask")
                        .font(.system(size: 13))
                        .foregroundStyle(sel ? Color(hex: "#8b6bff") : Color.t3)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(bottle.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(sel ? Color.t1 : Color.t2)
                        Text(bottle.config.renderer.rawValue)
                            .font(.system(size: 10))
                            .foregroundStyle(Color.t4)
                    }
                    Spacer()
                    if sel {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "#8b6bff"))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(sel ? Color(hex: "#8b6bff").opacity(0.12) : Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(sel ? Color(hex: "#8b6bff").opacity(0.4) : Color.stroke, lineWidth: sel ? 1 : 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture { selectedBottleId = bottle.id }
            }
        }
    }

    private var customInstallerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Installer File")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.t2)
                .padding(.top, 14)

            Button(action: pickInstaller) {
                HStack(spacing: 10) {
                    Image(systemName: customInstallerPath.isEmpty ? "doc.badge.plus" : "doc.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(customInstallerPath.isEmpty ? Color.t3 : Color.accent)
                    Text(customInstallerPath.isEmpty ? "Choose installer (.exe, .msi)…" :
                         URL(fileURLWithPath: customInstallerPath).lastPathComponent)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(customInstallerPath.isEmpty ? Color.t3 : Color.t1)
                        .lineLimit(1).truncationMode(.middle)
                    Spacer()
                    Text("Browse").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.accent)
                }
                .frame(height: 38)
                .padding(.horizontal, 13)
                .background(Color.black.opacity(0.28))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(customInstallerPath.isEmpty ? Color.stroke2 : Color(hex: "#8b6bff"), lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 9))
            }
            .buttonStyle(.plain)

            if !customInstallerPath.isEmpty {
                TextField("App name (shown in library)", text: $customAppName)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.t1)
                    .textFieldStyle(.plain)
                    .frame(height: 34)
                    .padding(.horizontal, 12)
                    .background(Color.black.opacity(0.28))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.stroke2, lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var installStatusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if isInstalling {
                    ProgressView().scaleEffect(0.7)
                } else if installerRunning {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.statusAmber)
                }
                Text(installStatus)
                    .font(.system(size: 12))
                    .foregroundStyle(installerRunning ? Color.t1 : Color.t2)
                    .lineLimit(2)
                Spacer()
            }

            if isInstalling && installProgress > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.08)).frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient.accent)
                            .frame(width: geo.size.width * installProgress, height: 5)
                    }
                }
                .frame(height: 5)
            }
        }
        .padding(14)
        .background(Color.black.opacity(0.2))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.stroke, lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Actions

    private func pickInstaller() {
        Task {
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                DispatchQueue.main.async {
                    let panel = NSOpenPanel()
                    panel.title = "Escolher instalador"
                    panel.allowedContentTypes = [
                        UTType(filenameExtension: "exe") ?? .data,
                        UTType(filenameExtension: "msi") ?? .data,
                    ]
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        customInstallerPath = url.path
                        if customAppName.isEmpty {
                            customAppName = url.deletingPathExtension().lastPathComponent
                        }
                    }
                    cont.resume()
                }
            }
        }
    }

    private func startInstall() {
        guard let bottleId = selectedBottleId,
              let bottle = bottleVM.bottles.first(where: { $0.id == bottleId }) else { return }

        installError = nil
        isInstalling = true
        installProgress = 0

        Task {
            do {
                let installerPath = try await downloadInstaller()
                isInstalling = false
                installerRunning = true
                installStatus = "Instalador aberto — conclua a instalação na janela que apareceu."

                let (process, stream) = try await WineService.shared.runInstaller(at: installerPath, in: bottle.prefixURL)
                for await _ in stream {}

                // Auto-register after installer exits
                if let app = selectedApp {
                    let winPath = "C:\\" + app.defaultExeRelativePath.replacingOccurrences(of: "/", with: "\\")
                    let realPath = bottle.prefixURL
                        .appending(path: "drive_c")
                        .appending(path: app.defaultExeRelativePath)
                    if FileManager.default.fileExists(atPath: realPath.path) {
                        // Install no-sandbox wrapper for Steam immediately after install
                        try? await SteamService.shared.installWrapper(in: bottle.prefixURL)

                        let game = try? await GameService.shared.add(
                            name: app.name,
                            exePath: winPath,
                            bottleId: bottleId,
                            launchArgs: app.defaultLaunchArgs
                        )
                        if let game { libraryVM.appendGame(game) }
                    }
                } else if isCustom && !customAppName.isEmpty {
                    // The installer's own path is NOT the game's exe — ask the user
                    // to point at the actual executable installed inside the bottle.
                    installStatus = "Selecione o executável do jogo instalado…"
                    let driveC = bottle.prefixURL.appending(path: "drive_c")
                    if let exeURL = await libraryVM.pickExeFile(startingAt: driveC) {
                        let winPath = Self.windowsPath(fromMacPath: exeURL.path, driveC: driveC.path)
                        let game = try? await GameService.shared.add(
                            name: customAppName,
                            exePath: winPath,
                            bottleId: bottleId,
                            launchArgs: ""
                        )
                        if let game { libraryVM.appendGame(game) }
                    }
                }

                isPresented = false
            } catch {
                isInstalling = false
                installerRunning = false
                installError = error.localizedDescription
            }
        }
    }

    /// Converts an absolute macOS path (inside a bottle's drive_c) into a Windows-style
    /// path (e.g. "C:\Program Files\Game\game.exe") so Wine can launch it later.
    private static func windowsPath(fromMacPath macPath: String, driveC: String) -> String {
        guard macPath.hasPrefix(driveC) else { return macPath }
        let relative = macPath
            .dropFirst(driveC.count)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return "C:\\" + relative.replacingOccurrences(of: "/", with: "\\")
    }

    private func downloadInstaller() async throws -> String {
        if isCustom { return customInstallerPath }
        guard let app = selectedApp else { throw BarrelError.downloadFailed }
        guard let url = URL(string: app.installerURL) else { throw BarrelError.downloadFailed }

        installStatus = "Baixando \(app.name)..."
        let filename = url.lastPathComponent.isEmpty ? "\(app.id)-installer.exe" : url.lastPathComponent
        let dest = StorageManager.shared.cacheDirectory.appending(path: filename)

        let tempURL = try await DownloadService.shared.downloadFile(from: url) { p in
            Task { @MainActor in installProgress = p }
        }
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.moveItem(at: tempURL, to: dest)
        return dest.path
    }
}

// MARK: - App catalog card

struct AppCatalogCard: View {
    let app: KnownApp
    let selected: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color(hex: app.accentHex).opacity(selected ? 0.25 : 0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: app.symbol)
                    .font(.system(size: 17))
                    .foregroundStyle(Color(hex: app.accentHex))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.t1)
                Text(app.tagline)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.t3)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: "#8b6bff"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(selected ? Color(hex: "#8b6bff").opacity(0.10) : Color.white.opacity(0.04))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(selected ? Color(hex: "#8b6bff").opacity(0.5) : Color.stroke, lineWidth: selected ? 1 : 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Custom installer card

struct CustomInstallerCard: View {
    let selected: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color.white.opacity(selected ? 0.12 : 0.06))
                    .frame(width: 38, height: 38)
                Image(systemName: "folder.fill.badge.plus")
                    .font(.system(size: 16))
                    .foregroundStyle(selected ? Color.t1 : Color.t3)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Custom Installer")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.t1)
                Text("Run any .exe or .msi installer")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.t3)
            }
            Spacer(minLength: 0)
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: "#8b6bff"))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(selected ? Color(hex: "#8b6bff").opacity(0.10) : Color.white.opacity(0.04))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(selected ? Color(hex: "#8b6bff").opacity(0.5) : Color.stroke, lineWidth: selected ? 1 : 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

import SwiftUI

struct GameDetailView: View {
    let game: Game
    let bottle: Bottle
    var onBack: (() -> Void)? = nil

    @StateObject private var vm = GameDetailViewModel()

    private var gameData: GameData { GameData.from(game, bottle: bottle) }

    var body: some View {
        ZStack {
            Color.contentBg.ignoresSafeArea()
            VStack(spacing: 0) {
                GameDetailToolbar(title: gameData.title, onBack: onBack)
                ScrollView {
                    VStack(spacing: 0) {
                        HeroView(
                            game: gameData,
                            isRunning: vm.isRunning,
                            onPlay: { Task { await vm.launch(game, in: bottle) } },
                            onStop: { vm.stop() }
                        )
                        GameBodyView(bottle: bottle, game: game, logs: vm.logs, isRunning: vm.isRunning)
                    }
                }
            }
        }
    }
}

struct GameDetailToolbar: View {
    let title: String
    var onBack: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "sidebar.left").font(.system(size: 17)).foregroundStyle(Color.t2).frame(width: 30, height: 30)
            Button(action: { onBack?() }) {
                Image(systemName: "chevron.left").font(.system(size: 16)).foregroundStyle(Color.t2).frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            Text(title).font(.system(size: 15, weight: .semibold)).tracking(-0.1).foregroundStyle(Color.t1)
            Spacer()
            Image(systemName: "folder").font(.system(size: 16)).foregroundStyle(Color.t2).frame(width: 30, height: 30)
            Image(systemName: "ellipsis").font(.system(size: 17)).foregroundStyle(Color.t2).frame(width: 30, height: 30)
        }
        .frame(height: 52).padding(.horizontal, 18)
        .background(Color(hex: "#1c1c1f").opacity(0.72).background(.ultraThinMaterial))
        .overlay(alignment: .bottom) { Rectangle().fill(Color.black.opacity(0.45)).frame(height: 0.5) }
    }
}

struct HeroView: View {
    let game: GameData
    var isRunning: Bool = false
    var onPlay: () -> Void = {}
    var onStop: () -> Void = {}

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .bottom) {
                CoverArtView(game: game, cornerRadius: 0)

                LinearGradient(
                    stops: [
                        .init(color: Color.contentBg, location: 0.02),
                        .init(color: Color.contentBg.opacity(0.2), location: 0.46),
                        .init(color: Color.contentBg.opacity(0.55), location: 1),
                    ],
                    startPoint: .bottom, endPoint: .top
                )

                HStack(alignment: .bottom, spacing: 20) {
                    // box art thumbnail
                    ZStack {
                        CoverArtView(game: game, cornerRadius: 12)
                            .frame(width: 120, height: 160)
                            .shadow(color: .black.opacity(0.55), radius: 30, y: 12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.14), lineWidth: 0.5))

                        VStack {
                            Spacer()
                            LinearGradient(colors: [Color.black.opacity(0.62), .clear], startPoint: .bottom, endPoint: .top)
                                .frame(height: 50)
                                .overlay(alignment: .bottomLeading) {
                                    Text(game.title)
                                        .font(.system(size: 17, weight: .black))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 9)
                                        .padding(.bottom, 10)
                                        .lineLimit(2)
                                }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .frame(width: 120, height: 160)

                    // title + chips
                    VStack(alignment: .leading, spacing: 11) {
                        Text(game.title.prefix(1) + game.title.dropFirst().lowercased())
                            .font(.system(size: 34, weight: .black))
                            .tracking(-0.8)
                            .foregroundStyle(Color.t1)
                            .lineLimit(1)

                        HStack(spacing: 10) {
                            HeroChip { HStack(spacing: 6) {
                                Circle().fill(game.bottleColor).frame(width: 8, height: 8)
                                Text(game.bottleName).font(.system(size: 12, weight: .semibold))
                            }}
                            if isRunning {
                                HeroChip { HStack(spacing: 6) {
                                    Circle().fill(Color.statusGreen).frame(width: 7, height: 7)
                                    Text("Running").font(.system(size: 12, weight: .semibold))
                                }}
                            }
                        }
                    }
                    .padding(.bottom, 6)

                    Spacer()

                    // play/stop button
                    Button(action: isRunning ? onStop : onPlay) {
                        HStack(spacing: 9) {
                            Image(systemName: isRunning ? "stop.fill" : "play.fill").font(.system(size: 17))
                            Text(isRunning ? "Stop" : "Play").font(.system(size: 17, weight: .bold)).tracking(-0.1)
                        }
                        .foregroundStyle(.white)
                        .frame(height: 50)
                        .padding(.horizontal, 30)
                        .background(isRunning ? AnyShapeStyle(Color.statusRed) : AnyShapeStyle(LinearGradient.accent))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color(hex: "#7c5cff").opacity(0.4), radius: 22, y: 8)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.35), lineWidth: 0.5).blendMode(.plusLighter))
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 6)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 22)
            }
        }
        .frame(height: 300)
    }
}

struct HeroChip<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        content()
            .foregroundStyle(Color.t1)
            .frame(height: 26)
            .padding(.horizontal, 11)
            .background(Color.black.opacity(0.35).background(.ultraThinMaterial))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.stroke2, lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

struct GameBodyView: View {
    let bottle: Bottle
    let game: Game
    let logs: [LogEntry]
    let isRunning: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            // left column — real bottle/game configuration (read-only)
            VStack(spacing: 16) {
                VStack(spacing: 0) {
                    PanelHeader(icon: "slider.horizontal.3", label: "Configuration")
                    ConfigInfoRow(label: "Renderer", value: bottle.config.renderer.rawValue)
                    ConfigInfoRow(label: "Architecture", value: bottle.config.arch.rawValue)
                    ConfigInfoRow(label: "ESync", value: bottle.config.esync ? "On" : "Off")
                    ConfigInfoRow(label: "MSync", value: bottle.config.msync ? "On" : "Off")
                    ConfigInfoRow(label: "Executable", value: game.exePath, isLast: game.launchArgs.isEmpty)

                    if !game.launchArgs.isEmpty {
                        Text("Launch arguments")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.4)
                            .textCase(.uppercase)
                            .foregroundStyle(Color.t3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 11)
                            .padding(.bottom, 4)

                        Text(game.launchArgs)
                            .font(.system(size: 12).monospaced())
                            .foregroundStyle(Color(red: 235/255, green: 235/255, blue: 245/255).opacity(0.78))
                            .lineSpacing(6)
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.28))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.stroke2, lineWidth: 0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 14)
                    }
                }
                .background(Color.card)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stroke, lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // right column — live console
            LiveLogConsoleView(logs: logs, isRunning: isRunning)
        }
        .padding(.horizontal, 30)
        .padding(.top, 24)
        .padding(.bottom, 28)
        .frame(minHeight: 400)
    }
}

struct PanelHeader: View {
    let icon: String
    let label: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 13))
            Text(label).font(.system(size: 12, weight: .bold)).tracking(0.4).textCase(.uppercase)
        }
        .foregroundStyle(Color.t2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 44)
        .padding(.horizontal, 16)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.stroke).frame(height: 0.5) }
    }
}

/// Read-only row showing a real config value (renderer, sync mode, exe path, etc.)
struct ConfigInfoRow: View {
    let label: String
    let value: String
    var isLast: Bool = false

    var body: some View {
        HStack {
            Text(label).font(.system(size: 13.5, weight: .medium)).foregroundStyle(Color.t1)
            Spacer()
            Text(value)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(Color.t2)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(Color.stroke).frame(height: 0.5) }
        }
    }
}

// MARK: - Live Log Console (driven by GameDetailViewModel.logs)

struct LiveLogConsoleView: View {
    let logs: [LogEntry]
    let isRunning: Bool

    var body: some View {
        VStack(spacing: 0) {
            // header
            HStack(spacing: 8) {
                Image(systemName: "terminal").font(.system(size: 13))
                Text("Console").font(.system(size: 12, weight: .bold)).tracking(0.4).textCase(.uppercase)
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(isRunning ? Color.statusGreen : Color.t4)
                        .frame(width: 7, height: 7)
                        .shadow(color: isRunning ? Color.statusGreen.opacity(0.6) : .clear, radius: 4)
                    Text(isRunning ? "RUNNING" : "STOPPED")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.4)
                        .foregroundStyle(isRunning ? Color.statusGreen : Color.t4)
                }
            }
            .foregroundStyle(Color.t2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 44)
            .padding(.horizontal, 16)
            .background(Color.card)
            .overlay(alignment: .bottom) { Rectangle().fill(Color.stroke).frame(height: 0.5) }

            // log lines
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if logs.isEmpty {
                            Text(isRunning ? "Starting…" : "No output yet — press Play to launch.")
                                .font(.system(size: 12).monospaced())
                                .foregroundStyle(Color.t3)
                                .padding(.vertical, 4)
                        }
                        ForEach(logs) { entry in
                            RealLogLine(entry: entry).id(entry.id)
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                }
                .onChange(of: logs.count) { _ in
                    if let last = logs.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .background(Color.black.opacity(0.34))
        }
        .background(Color.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stroke, lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct RealLogLine: View {
    let entry: LogEntry

    private var levelColor: Color {
        switch entry.level {
        case .error:   return .statusRed
        case .warning: return .statusAmber
        case .info:    return .statusBlue
        }
    }

    private var prefix: String {
        switch entry.level {
        case .error:   return "✗ "
        case .warning: return "⚠ "
        case .info:    return "› "
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(prefix)
                .foregroundStyle(levelColor)
                .font(.system(size: 11.5).monospaced())
            Text(entry.message)
                .foregroundStyle(Color(red: 235/255, green: 235/255, blue: 245/255).opacity(0.78))
                .font(.system(size: 11.5).monospaced())
                .lineLimit(nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineSpacing(4)
    }
}

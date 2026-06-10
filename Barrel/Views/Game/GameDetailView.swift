import SwiftUI

struct GameDetailView: View {
    let game: GameData = sampleGames[0] // Ashfall

    var body: some View {
        ZStack {
            Color.contentBg.ignoresSafeArea()
            VStack(spacing: 0) {
                GameDetailToolbar(title: game.title)
                ScrollView {
                    VStack(spacing: 0) {
                        HeroView(game: game)
                        GameBodyView(game: game)
                    }
                }
            }
        }
    }
}

struct GameDetailToolbar: View {
    let title: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "sidebar.left").font(.system(size: 17)).foregroundStyle(Color.t2).frame(width: 30, height: 30)
            Image(systemName: "chevron.left").font(.system(size: 16)).foregroundStyle(Color.t4).frame(width: 30, height: 30)
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
                            HeroChip { HStack(spacing: 6) {
                                Image(systemName: "display").font(.system(size: 12))
                                Text("DirectX 12").font(.system(size: 12, weight: .semibold))
                            }}
                            HeroChip { Text(game.genre).font(.system(size: 12, weight: .semibold)) }
                            HeroChip { HStack(spacing: 6) {
                                Image(systemName: "clock").font(.system(size: 12))
                                Text("24.6 h played").font(.system(size: 12, weight: .semibold))
                            }}
                        }
                    }
                    .padding(.bottom, 6)

                    Spacer()

                    // play button
                    Button(action: {}) {
                        HStack(spacing: 9) {
                            Image(systemName: "play.fill").font(.system(size: 17))
                            Text("Play").font(.system(size: 17, weight: .bold)).tracking(-0.1)
                        }
                        .foregroundStyle(.white)
                        .frame(height: 50)
                        .padding(.horizontal, 30)
                        .background(LinearGradient.accent)
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
    let game: GameData

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            // left column — configuration
            VStack(spacing: 16) {
                VStack(spacing: 0) {
                    PanelHeader(icon: "slider.horizontal.3", label: "Configuration")
                    ConfigRow(label: "Resolution", sublabel: "Native display · 16:9") {
                        SelectControl(label: "2560 × 1440")
                    }
                    ConfigRow(label: "Display Mode", sublabel: "Borderless recommended") {
                        SelectControl(label: "Fullscreen")
                    }
                    ConfigRow(label: "Esync / Fsync", sublabel: "Lower CPU overhead") {
                        ToggleControl(on: true)
                    }
                    ConfigRow(label: "DXVK HUD overlay", sublabel: "FPS · frametime · GPU") {
                        ToggleControl(on: false)
                    }
                    ConfigRow(label: "Feral GameMode", sublabel: "Performance governor") {
                        ToggleControl(on: true)
                    }

                    Text("Launch arguments")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.4)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.t3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 11)
                        .padding(.bottom, 4)

                    Text(AttributedString.launchArgs)
                        .font(.system(size: 12).monospaced())
                        .lineSpacing(6)
                        .padding(.horizontal, 12).padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.28))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.stroke2, lineWidth: 0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                }
                .background(Color.card)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stroke, lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // right column — console
            LogConsoleView()
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

struct ConfigRow<Ctrl: View>: View {
    let label: String
    let sublabel: String
    @ViewBuilder let control: () -> Ctrl
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 13.5, weight: .medium)).foregroundStyle(Color.t1)
                Text(sublabel).font(.system(size: 11.5)).foregroundStyle(Color.t3)
            }
            Spacer()
            control()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.stroke).frame(height: 0.5) }
    }
}

struct SelectControl: View {
    let label: String
    var body: some View {
        HStack(spacing: 8) {
            Text(label).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(Color.t1)
            Image(systemName: "chevron.down").font(.system(size: 11)).foregroundStyle(Color.t2)
        }
        .frame(height: 28).padding(.horizontal, 8).padding(.leading, 3)
        .background(Color.fieldBg)
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.stroke2, lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

struct ToggleControl: View {
    let on: Bool
    var body: some View {
        ZStack(alignment: on ? .trailing : .leading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(on ? Color.statusGreen : Color.white.opacity(0.16))
            Circle().fill(.white).shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                .padding(2)
                .frame(width: 23, height: 23)
        }
        .frame(width: 38, height: 23)
    }
}

extension AttributedString {
    static var launchArgs: AttributedString {
        var s = AttributedString("WINEDEBUG=-all DXVK_FRAME_RATE=144 %command% --skip-intro")
        s.foregroundColor = Color(red: 235/255, green: 235/255, blue: 245/255).opacity(0.78)
        return s
    }
}

// MARK: - Log Console
struct LogConsoleView: View {
    static let logScript: [(ts: String, level: String, message: String)] = [
        ("00:00.04", "i",   "wine: prefix ~/Library/Bottles/Gaming · win11 (64-bit)"),
        ("00:00.21", "dim", "fixme:winediag:loader  wine-9.0 launching Ashfall.exe"),
        ("00:00.55", "ok",  "dxvk: Game: Ashfall.exe"),
        ("00:00.56", "ok",  "dxvk: DXVK 2.4"),
        ("00:00.83", "i",   "dxvk: Vulkan device — Apple M3 Pro (MoltenVK 1.2)"),
        ("00:01.10", "dim", "fixme:d3d12  vkd3d: Direct3D 12 device created"),
        ("00:01.34", "i",   "dxvk: adapter memory 18432 MB · resizable BAR on"),
        ("00:01.62", "ok",  "steam_api: initialized · appid 204410"),
        ("00:02.05", "i",   "engine: warming shader cache (12480 pipelines)"),
        ("00:02.49", "w",   "warn:hid  controller hot-plug deferred → XInput"),
        ("00:02.71", "i",   "engine: mounting pak archives [4/4]"),
        ("00:03.08", "i",   "audio: WASAPI → CoreAudio · 48000 Hz · 5.1"),
        ("00:03.40", "ok",  "render: swapchain 2560×1440 fullscreen @ 144 Hz"),
        ("00:03.62", "ok",  "Ashfall: main menu ready — 3.62s"),
    ]

    @State private var visibleCount = 0

    var body: some View {
        VStack(spacing: 0) {
            // header
            HStack(spacing: 8) {
                Image(systemName: "terminal").font(.system(size: 13))
                Text("Console").font(.system(size: 12, weight: .bold)).tracking(0.4).textCase(.uppercase)
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.statusGreen)
                        .frame(width: 7, height: 7)
                        .shadow(color: Color.statusGreen.opacity(0.6), radius: 4)
                    Text(visibleCount >= Self.logScript.count ? "RUNNING" : "LAUNCHING")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.4)
                        .foregroundStyle(Color.statusGreen)
                }
                Text("00:03.62")
                    .font(.system(size: 11).monospaced())
                    .foregroundStyle(Color.t3)
                    .padding(.leading, 12)
            }
            .foregroundStyle(Color.t2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 44)
            .padding(.horizontal, 16)
            .background(Color.card)
            .overlay(alignment: .bottom) { Rectangle().fill(Color.stroke).frame(height: 0.5) }

            // log lines
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(Self.logScript.prefix(visibleCount).enumerated()), id: \.offset) { _, entry in
                        LogLine(ts: entry.ts, level: entry.level, message: entry.message)
                    }
                    // cursor
                    Text("▋")
                        .font(.system(size: 12).monospaced())
                        .foregroundStyle(Color.statusGreen)
                        .opacity(visibleCount < Self.logScript.count ? 1 : 0)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .background(Color.black.opacity(0.34))
        }
        .background(Color.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stroke, lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear { animateLogs() }
    }

    private func animateLogs() {
        guard visibleCount < Self.logScript.count else { return }
        let delay = visibleCount == 0 ? 0.26 : 0.52
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            visibleCount += 1
            animateLogs()
        }
    }
}

struct LogLine: View {
    let ts: String
    let level: String
    let message: String

    var levelColor: Color {
        switch level {
        case "ok":  return .statusGreen
        case "w":   return .statusAmber
        case "i":   return .statusBlue
        default:    return .t3
        }
    }

    var prefix: String {
        switch level {
        case "ok": return "✓ "
        case "w":  return "⚠ "
        case "i":  return "› "
        default:   return "  "
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(ts + "  ")
                .foregroundStyle(Color.t4)
                .font(.system(size: 11.5).monospaced())
            Text(prefix)
                .foregroundStyle(levelColor)
                .font(.system(size: 11.5).monospaced())
            Text(message)
                .foregroundStyle(level == "dim" ? Color.t3 : Color(red: 235/255, green: 235/255, blue: 245/255).opacity(0.78))
                .font(.system(size: 11.5).monospaced())
                .lineLimit(nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineSpacing(4)
    }
}

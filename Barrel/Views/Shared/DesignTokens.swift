import SwiftUI

// MARK: - Colors
extension Color {
    static let winBg        = Color(hex: "#1c1c1e")
    static let contentBg    = Color(hex: "#1a1a1c")
    static let sidebarBg    = Color(hex: "#201e26").opacity(0.62)
    static let toolbarBg    = Color(hex: "#1c1c1f").opacity(0.72)
    static let card         = Color.white.opacity(0.055)
    static let card2        = Color.white.opacity(0.08)
    static let cardHover    = Color.white.opacity(0.10)
    static let fieldBg      = Color.white.opacity(0.07)

    static let stroke       = Color.white.opacity(0.085)
    static let stroke2      = Color.white.opacity(0.14)
    static let stroke3      = Color.white.opacity(0.20)

    static let t1           = Color(hex: "#f4f4f6")
    static let t2           = Color(red: 235/255, green: 235/255, blue: 245/255).opacity(0.62)
    static let t3           = Color(red: 235/255, green: 235/255, blue: 245/255).opacity(0.34)
    static let t4           = Color(red: 235/255, green: 235/255, blue: 245/255).opacity(0.20)

    static let accent       = Color(hex: "#8b6bff")
    static let accentDeep   = Color(hex: "#6f54f0")
    static let accent2      = Color(hex: "#ff8a3d")

    static let statusGreen  = Color(hex: "#34c759")
    static let statusBlue   = Color(hex: "#4aa3ff")
    static let statusAmber  = Color(hex: "#ffb340")
    static let statusRed    = Color(hex: "#ff5a52")

    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let accent = LinearGradient(
        stops: [
            .init(color: Color(hex: "#9a6bff"), location: 0),
            .init(color: Color(hex: "#7c5cff"), location: 0.42),
            .init(color: Color(hex: "#ff7a3d"), location: 1.3),
        ],
        startPoint: UnitPoint(x: 0, y: 0.5),
        endPoint: UnitPoint(x: 1.3, y: 0.5)
    )
    static let accentSoft = LinearGradient(
        stops: [
            .init(color: Color(hex: "#9a6bff").opacity(0.22), location: 0),
            .init(color: Color(hex: "#ff7a3d").opacity(0.22), location: 1),
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Wallpaper
struct WallpaperView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "#15151b"), location: 0),
                    .init(color: Color(hex: "#0f0f13"), location: 1),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(colors: [Color(hex: "#3a2f63"), .clear], center: UnitPoint(x: 0, y: 0), startRadius: 0, endRadius: 600)
                .opacity(1)
            RadialGradient(colors: [Color(hex: "#7a3f57"), .clear], center: UnitPoint(x: 0.08, y: 1), startRadius: 0, endRadius: 500)
                .opacity(1)
            RadialGradient(colors: [Color(hex: "#243154"), .clear], center: UnitPoint(x: 1, y: 0), startRadius: 0, endRadius: 550)
                .opacity(1)
        }
    }
}

// MARK: - Traffic Lights
struct TrafficLights: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(Color(hex: "#ff5f57")).frame(width: 12, height: 12)
            Circle().fill(Color(hex: "#febc2e")).frame(width: 12, height: 12)
            Circle().fill(Color(hex: "#28c840")).frame(width: 12, height: 12)
        }
    }
}

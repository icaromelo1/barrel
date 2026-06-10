import SwiftUI

struct GameData: Identifiable {
    let id: String
    let title: String
    let genre: String
    let bottleColor: Color
    let bottleName: String
    let palette: (Color, Color, Color)
    let glowColor: Color
    let motif: Motif
    let titleSize: CGFloat

    enum Motif { case peak, grid, orbit, slash, ring, bolt }
}

let sampleGames: [GameData] = [
    GameData(id: "ashfall",   title: "ASHFALL",        genre: "Survival",     bottleColor: Color(hex: "#8b6bff"), bottleName: "Gaming",   palette: (Color(hex: "#2a0d08"), Color(hex: "#b3401c"), Color(hex: "#ff7a2f")), glowColor: Color(hex: "#ff5e1e"), motif: .peak,  titleSize: 30),
    GameData(id: "neondrift", title: "NEON DRIFT",     genre: "Racing",       bottleColor: Color(hex: "#34c759"), bottleName: "Arcade",   palette: (Color(hex: "#10052e"), Color(hex: "#5b1fb0"), Color(hex: "#ff3da6")), glowColor: Color(hex: "#ff3da6"), motif: .grid,  titleSize: 23),
    GameData(id: "verdant",   title: "VERDANT HOLLOW", genre: "RPG",          bottleColor: Color(hex: "#8b6bff"), bottleName: "Gaming",   palette: (Color(hex: "#04140d"), Color(hex: "#0f6b43"), Color(hex: "#5ad18a")), glowColor: Color(hex: "#3fd17e"), motif: .orbit, titleSize: 20),
    GameData(id: "ironclad",  title: "IRONCLAD",       genre: "Strategy",     bottleColor: Color(hex: "#4aa3ff"), bottleName: "Strategy", palette: (Color(hex: "#0a1422"), Color(hex: "#274b73"), Color(hex: "#7fb2e6")), glowColor: Color(hex: "#5c93d6"), motif: .slash, titleSize: 28),
    GameData(id: "starfarer", title: "STARFARER",      genre: "Sci-Fi",       bottleColor: Color(hex: "#8b6bff"), bottleName: "Gaming",   palette: (Color(hex: "#070a1e"), Color(hex: "#2d2a8c"), Color(hex: "#6ad0ff")), glowColor: Color(hex: "#6ad0ff"), motif: .orbit, titleSize: 24),
    GameData(id: "palemoon",  title: "PALE MOON",      genre: "Mystery",      bottleColor: Color(hex: "#ff8a3d"), bottleName: "Classics", palette: (Color(hex: "#0c0a18"), Color(hex: "#3a3470"), Color(hex: "#b9a7ff")), glowColor: Color(hex: "#9b86ff"), motif: .ring,  titleSize: 26),
    GameData(id: "circuit",   title: "CIRCUIT BREAK",  genre: "Action",       bottleColor: Color(hex: "#34c759"), bottleName: "Arcade",   palette: (Color(hex: "#161200"), Color(hex: "#9a7a00"), Color(hex: "#ffe23d")), glowColor: Color(hex: "#ffd21e"), motif: .bolt,  titleSize: 21),
    GameData(id: "hollow",    title: "HOLLOW REIGN",   genre: "Dark Fantasy", bottleColor: Color(hex: "#8b6bff"), bottleName: "Gaming",   palette: (Color(hex: "#1a0510"), Color(hex: "#7a0f33"), Color(hex: "#ff5a7a")), glowColor: Color(hex: "#ff3f63"), motif: .slash, titleSize: 23),
    GameData(id: "tide",      title: "TIDEBREAKER",    genre: "Strategy",     bottleColor: Color(hex: "#4aa3ff"), bottleName: "Strategy", palette: (Color(hex: "#041417"), Color(hex: "#0c6a72"), Color(hex: "#52e0d4")), glowColor: Color(hex: "#34d4c8"), motif: .ring,  titleSize: 24),
    GameData(id: "lumen",     title: "LUMEN",          genre: "Puzzle",       bottleColor: Color(hex: "#34c759"), bottleName: "Arcade",   palette: (Color(hex: "#0a0f1a"), Color(hex: "#3a5fb0"), Color(hex: "#cfe6ff")), glowColor: Color(hex: "#9cc3ff"), motif: .orbit, titleSize: 30),
]

struct CoverArtView: View {
    let game: GameData
    var cornerRadius: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [game.palette.0, game.palette.1, game.palette.2],
                    startPoint: UnitPoint(x: 0.15, y: 0),
                    endPoint: UnitPoint(x: 1.0, y: 1.45)
                )
                // glow blobs
                Ellipse()
                    .fill(game.glowColor)
                    .blur(radius: 18)
                    .opacity(0.85)
                    .frame(width: geo.size.width * 0.85, height: geo.size.height * 0.55)
                    .offset(x: geo.size.width * 0.18, y: -geo.size.height * 0.12)
                Ellipse()
                    .fill(game.palette.1)
                    .blur(radius: 18)
                    .opacity(0.6)
                    .frame(width: geo.size.width * 0.6, height: geo.size.height * 0.45)
                    .offset(x: -geo.size.width * 0.15, y: geo.size.height * 0.08)
                MotifView(game: game)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}

struct MotifView: View {
    let game: GameData

    var body: some View {
        Canvas { ctx, size in
            let c = game.palette.2
            let g = game.glowColor
            let w = size.width
            let h = size.height
            let scaleX = w / 100
            let scaleY = h / 100

            switch game.motif {
            case .peak:
                var path = Path()
                path.move(to: CGPoint(x: 8 * scaleX, y: 78 * scaleY))
                path.addLine(to: CGPoint(x: 34 * scaleX, y: 30 * scaleY))
                path.addLine(to: CGPoint(x: 52 * scaleX, y: 58 * scaleY))
                path.addLine(to: CGPoint(x: 68 * scaleX, y: 24 * scaleY))
                path.addLine(to: CGPoint(x: 92 * scaleX, y: 78 * scaleY))
                ctx.fill(path, with: .color(g.opacity(0.12)))
                ctx.stroke(path, with: .color(c.opacity(0.9)), lineWidth: 2.4 * min(scaleX, scaleY))

            case .grid:
                for i in 0..<5 {
                    let y = (36 + i * 13) * scaleY
                    var line = Path()
                    line.move(to: CGPoint(x: 6 * scaleX, y: y))
                    line.addLine(to: CGPoint(x: 94 * scaleX, y: y))
                    ctx.stroke(line, with: .color(c.opacity(0.25 + Double(i) * 0.14)), lineWidth: 1.6)
                }
                for i in -2...2 {
                    var line = Path()
                    line.move(to: CGPoint(x: (50 + i * 9) * scaleX, y: 36 * scaleY))
                    line.addLine(to: CGPoint(x: (50 + i * 34) * scaleX, y: 94 * scaleY))
                    ctx.stroke(line, with: .color(c.opacity(0.4)), lineWidth: 1.4)
                }

            case .orbit:
                var c1 = Path(); c1.addEllipse(in: CGRect(x: (50-30)*scaleX, y: (50-30)*scaleY, width: 60*scaleX, height: 60*scaleY))
                ctx.stroke(c1, with: .color(c.opacity(0.55)), lineWidth: 2)
                var e1 = Path()
                let cx = 50 * scaleX, cy = 50 * scaleY
                e1.addEllipse(in: CGRect(x: cx - 42*scaleX, y: cy - 16*scaleY, width: 84*scaleX, height: 32*scaleY))
                ctx.stroke(e1, with: .color(c.opacity(0.4)), lineWidth: 1.6)
                var c2 = Path(); c2.addEllipse(in: CGRect(x: (50-11)*scaleX, y: (50-11)*scaleY, width: 22*scaleX, height: 22*scaleY))
                ctx.fill(c2, with: .color(g.opacity(0.9)))
                ctx.stroke(c2, with: .color(.white.opacity(0.5)), lineWidth: 1)

            case .slash:
                var fill = Path()
                fill.move(to: CGPoint(x: 30*scaleX, y: 14*scaleY))
                fill.addLine(to: CGPoint(x: 70*scaleX, y: 14*scaleY))
                fill.addLine(to: CGPoint(x: 48*scaleX, y: 86*scaleY))
                fill.addLine(to: CGPoint(x: 8*scaleX, y: 86*scaleY))
                ctx.fill(fill, with: .color(g.opacity(0.16)))
                var stroke = Path()
                stroke.move(to: CGPoint(x: 44*scaleX, y: 12*scaleY))
                stroke.addLine(to: CGPoint(x: 74*scaleX, y: 12*scaleY))
                stroke.addLine(to: CGPoint(x: 52*scaleX, y: 88*scaleY))
                stroke.addLine(to: CGPoint(x: 22*scaleX, y: 88*scaleY))
                ctx.stroke(stroke, with: .color(c.opacity(1)), lineWidth: 2.6)
                var hline = Path()
                hline.move(to: CGPoint(x: 16*scaleX, y: 50*scaleY))
                hline.addLine(to: CGPoint(x: 84*scaleX, y: 50*scaleY))
                ctx.stroke(hline, with: .color(c.opacity(0.4)), lineWidth: 1.4)

            case .ring:
                var r1 = Path(); r1.addEllipse(in: CGRect(x: (50-32)*scaleX, y: (50-32)*scaleY, width: 64*scaleX, height: 64*scaleY))
                ctx.stroke(r1, with: .color(c.opacity(0.7)), lineWidth: 2.2)
                var r2 = Path(); r2.addEllipse(in: CGRect(x: (50-22)*scaleX, y: (50-22)*scaleY, width: 44*scaleX, height: 44*scaleY))
                ctx.stroke(r2, with: .color(c.opacity(0.4)), lineWidth: 1.4)

            case .bolt:
                var bolt = Path()
                bolt.move(to: CGPoint(x: 56*scaleX, y: 10*scaleY))
                bolt.addLine(to: CGPoint(x: 30*scaleX, y: 54*scaleY))
                bolt.addLine(to: CGPoint(x: 48*scaleX, y: 54*scaleY))
                bolt.addLine(to: CGPoint(x: 42*scaleX, y: 90*scaleY))
                bolt.addLine(to: CGPoint(x: 72*scaleX, y: 42*scaleY))
                bolt.addLine(to: CGPoint(x: 52*scaleX, y: 42*scaleY))
                bolt.closeSubpath()
                ctx.fill(bolt, with: .color(g.opacity(0.9)))
                ctx.stroke(bolt, with: .color(.white.opacity(0.4)), lineWidth: 1.2)
            }
        }
        .opacity(0.92)
    }
}

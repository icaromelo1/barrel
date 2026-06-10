import SwiftUI

struct GameCardView: View {
    let game: GameData
    var isRunning: Bool = false
    var onLaunch: () -> Void = {}

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topLeading) {
                // cover art
                CoverArtView(game: game)
                    .aspectRatio(3.0/4.0, contentMode: .fit)
                    .shadow(color: .black.opacity(0.4), radius: 18, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
                    )

                // genre badge
                if !game.genre.isEmpty {
                    Text(game.genre)
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.4).background(.ultraThinMaterial))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .padding(9)
                }

                // title gradient at bottom
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [Color.black.opacity(0.62), .clear],
                        startPoint: .bottom, endPoint: .top
                    )
                    .frame(height: 60)
                    .overlay(alignment: .bottomLeading) {
                        Text(game.title)
                            .font(.system(size: game.titleSize * 0.6, weight: .black))
                            .tracking(0.01 * game.titleSize)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 8, y: 1)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 13)
                            .lineLimit(2)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Hover overlay with play button
                if isHovered || isRunning {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(isRunning ? 0.5 : 0.38))
                        .overlay {
                            if isRunning {
                                VStack(spacing: 6) {
                                    ProgressView().tint(.white).scaleEffect(0.9)
                                    Text("Running")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            } else {
                                Button(action: onLaunch) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.18))
                                            .frame(width: 46, height: 46)
                                        Circle()
                                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                                            .frame(width: 46, height: 46)
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(.white)
                                            .offset(x: 2)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .transition(.opacity)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(isHovered && !isRunning ? 1.03 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
            .onHover { isHovered = $0 }

            // metadata below card
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(game.title.prefix(1) + game.title.dropFirst().lowercased())
                        .font(.system(size: 13.5, weight: .semibold))
                        .tracking(-0.1)
                        .foregroundStyle(Color.t1)
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        Circle()
                            .fill(game.bottleColor)
                            .frame(width: 7, height: 7)
                        Text(game.bottleName)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(Color.t2)
                    }
                }
                Spacer()
            }
        }
    }
}

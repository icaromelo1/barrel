import SwiftUI

struct GameCardView: View {
    let game: GameData

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
            }

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

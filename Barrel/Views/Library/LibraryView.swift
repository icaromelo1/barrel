import SwiftUI

struct LibraryView: View {
    @Binding var selectedBottle: String?
    @State private var showCreateBottle = false

    var filteredGames: [GameData] {
        guard let id = selectedBottle else { return sampleGames }
        return sampleGames.filter { $0.bottleName.lowercased() == id }
    }

    var title: String {
        guard let id = selectedBottle,
              let b = sampleBottles.first(where: { $0.id == id }) else { return "All Games" }
        return b.name
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.contentBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // toolbar
                LibraryToolbar(title: title, onAdd: { showCreateBottle = true })

                // content
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text(title)
                                .font(.system(size: 24, weight: .bold))
                                .tracking(-0.5)
                                .foregroundStyle(Color.t1)
                            Text("\(filteredGames.count) titles · 4 bottles")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.t3)
                        }
                        .padding(.bottom, 20)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 22), count: 5), spacing: 22) {
                            ForEach(filteredGames) { game in
                                GameCardView(game: game)
                            }
                        }
                    }
                    .padding(26)
                }
            }
        }
        .sheet(isPresented: $showCreateBottle) {
            CreateBottleSheet(isPresented: $showCreateBottle)
        }
    }
}

struct LibraryToolbar: View {
    let title: String
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "sidebar.left")
                .font(.system(size: 17))
                .foregroundStyle(Color.t2)
                .frame(width: 30, height: 30)

            Image(systemName: "chevron.left")
                .font(.system(size: 16))
                .foregroundStyle(Color.t4)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(-0.1)
                    .foregroundStyle(Color.t1)
            }

            Spacer()

            // segment control
            HStack(spacing: 2) {
                SegmentButton(icon: "square.grid.2x2.fill", active: true)
                SegmentButton(icon: "list.bullet", active: false)
            }
            .padding(2)
            .background(Color.white.opacity(0.06))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.stroke, lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 7))

            Image(systemName: "ellipsis")
                .font(.system(size: 17))
                .foregroundStyle(Color.t2)
                .frame(width: 30, height: 30)

            Button(action: onAdd) {
                HStack(spacing: 7) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Add Game")
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(-0.1)
                }
                .foregroundStyle(.white)
                .frame(height: 30)
                .padding(.horizontal, 14)
                .background(LinearGradient.accent)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                        .blendMode(.plusLighter)
                )
            }
            .buttonStyle(.plain)
        }
        .frame(height: 52)
        .padding(.horizontal, 18)
        .background(
            Color(hex: "#1c1c1f").opacity(0.72)
                .background(.ultraThinMaterial)
        )
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.black.opacity(0.45)).frame(height: 0.5)
        }
    }
}

struct SegmentButton: View {
    let icon: String
    let active: Bool

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 15))
            .foregroundStyle(active ? Color.t1 : Color.t3)
            .frame(width: 30, height: 24)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(active ? Color.white.opacity(0.12) : .clear)
                    .shadow(color: active ? .black.opacity(0.3) : .clear, radius: 1, y: 0.5)
            )
    }
}

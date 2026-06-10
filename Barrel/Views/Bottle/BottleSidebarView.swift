import SwiftUI

struct SidebarBottleData: Identifiable {
    let id: String
    let name: String
    let api: String
    let color: Color
    let count: Int
}

let sampleBottles = [
    SidebarBottleData(id: "gaming",   name: "Gaming",   api: "DX12",   color: Color(hex: "#8b6bff"), count: 6),
    SidebarBottleData(id: "classics", name: "Classics", api: "DX11",   color: Color(hex: "#ff8a3d"), count: 4),
    SidebarBottleData(id: "strategy", name: "Strategy", api: "DX11",   color: Color(hex: "#4aa3ff"), count: 3),
    SidebarBottleData(id: "arcade",   name: "Arcade",   api: "OpenGL", color: Color(hex: "#34c759"), count: 5),
]

struct BottleSidebarView: View {
    @Binding var selectedBottle: String?

    var body: some View {
        VStack(spacing: 0) {
            // top — traffic lights
            HStack {
                TrafficLights()
                Spacer()
            }
            .frame(height: 52)
            .padding(.horizontal, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // search bar
                    HStack(spacing: 7) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.t3)
                        Text("Search games")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.t3)
                        Spacer()
                    }
                    .frame(height: 30)
                    .padding(.horizontal, 9)
                    .background(Color.white.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.stroke, lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .padding(.bottom, 12)

                    // fixed items
                    SidebarRow(
                        icon: "square.grid.2x2.fill",
                        label: "All Games",
                        count: "18",
                        selected: selectedBottle == nil
                    )
                    .onTapGesture { selectedBottle = nil }

                    SidebarRow(icon: "clock", label: "Recently Played", selected: false)

                    // bottles section
                    Text("Bottles")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(Color.t3)
                        .textCase(.uppercase)
                        .padding(.horizontal, 10)
                        .padding(.top, 14)
                        .padding(.bottom, 5)

                    ForEach(sampleBottles) { bottle in
                        SidebarBottleRow(bottle: bottle, selected: selectedBottle == bottle.id)
                            .onTapGesture { selectedBottle = bottle.id }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }

            Divider().opacity(0.15)

            // footer
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 15))
                    Text("New Bottle")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(Color.t2)
                Spacer()
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.t2)
                    .frame(width: 30, height: 30)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
        }
        .frame(width: 248)
        .background(
            ZStack {
                WallpaperView()
                Color(hex: "#201e26").opacity(0.62)
            }
            .ignoresSafeArea()
        )
        .background(.ultraThinMaterial)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.black.opacity(0.4))
                .frame(width: 0.5)
        }
    }
}

struct SidebarRow: View {
    let icon: String
    let label: String
    var count: String? = nil
    let selected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .frame(width: 19)
                .foregroundStyle(selected ? Color.white : Color.t2)
            Text(label)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(Color.t1)
            Spacer()
            if let count {
                Text(count)
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundStyle(Color.t3)
            }
        }
        .frame(height: 34)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(selected ? Color.white.opacity(0.10) : .clear)
        )
    }
}

struct SidebarBottleRow: View {
    let bottle: SidebarBottleData
    let selected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "flask")
                .font(.system(size: 15))
                .frame(width: 19)
                .foregroundStyle(selected ? Color.white : bottle.color)
            Text(bottle.name)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(Color.t1)
            Spacer()
            Text(bottle.api)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(selected ? Color.white.opacity(0.7) : Color.t3)
        }
        .frame(height: 34)
        .padding(.horizontal, 10)
        .background(
            Group {
                if selected {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(LinearGradient(
                            colors: [Color(hex: "#8b6bff").opacity(0.30), Color(hex: "#8b6bff").opacity(0.16)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color(hex: "#8b6bff").opacity(0.35), lineWidth: 0.5)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 7).fill(Color.clear)
                }
            }
        )
    }
}

import SwiftUI


struct DependencyListView: View {
    let bottle: Bottle
    @StateObject private var depVM = DependencyViewModel()

    private var rendererLabel: String {
        switch bottle.config.renderer {
        case .dxvk:  return "DXVK (DX9/10/11)"
        case .metal: return "D3DMetal (DX12)"
        case .gl:    return "OpenGL"
        }
    }

    var body: some View {
        ZStack {
            Color.contentBg.ignoresSafeArea()

            VStack(spacing: 0) {
                DependencyToolbar(bottle: bottle)

                // bottle hero
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient(
                                    colors: [Color(hex: "#8b6bff"), Color(hex: "#8b6bff").opacity(0.6)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .frame(width: 56, height: 56)
                                .shadow(color: .black.opacity(0.35), radius: 16, y: 6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                                )
                            Image(systemName: "flask")
                                .font(.system(size: 26))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 7) {
                            Text(bottle.name)
                                .font(.system(size: 23, weight: .bold))
                                .tracking(-0.5)
                                .foregroundStyle(Color.t1)

                            HStack(spacing: 8) {
                                SpecChip(icon: "display", text: rendererLabel)
                                SpecChip(icon: "square.stack.3d.up", text: "Windows 11 · \(bottle.config.arch.rawValue)")
                                if !bottle.wineVersion.isEmpty {
                                    SpecChip(icon: "cpu", text: "Wine \(bottle.wineVersion)")
                                }
                            }
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 26)

                // tabs
                HStack(spacing: 0) {
                    TabItem(label: "Games", active: false)
                    TabItem(label: "Components", active: true)
                    TabItem(label: "Settings", active: false)
                    Spacer()
                }
                .padding(.horizontal, 30)
                .padding(.top, 22)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color.stroke).frame(height: 0.5)
                }

                // components grid
                ScrollView {
                    VStack(spacing: 14) {
                        HStack {
                            Text("Graphics & Runtime")
                                .font(.system(size: 13, weight: .bold))
                                .tracking(0.3)
                                .textCase(.uppercase)
                                .foregroundStyle(Color.t3)
                            Spacer()
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            ForEach(Dependency.all) { dep in
                                DependencyCard(dep: dep, bottle: bottle, depVM: depVM)
                            }
                        }
                    }
                    .padding(30)
                }
            }
        }
    }
}

struct DependencyToolbar: View {
    let bottle: Bottle

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "sidebar.left").font(.system(size: 17)).foregroundStyle(Color.t2).frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text(bottle.name).font(.system(size: 15, weight: .semibold)).tracking(-0.1).foregroundStyle(Color.t1)
                Text("Bottle · \(bottle.games.count) games").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.t3)
            }
            Spacer()
            Image(systemName: "folder").font(.system(size: 16)).foregroundStyle(Color.t2).frame(width: 30, height: 30)
            Image(systemName: "ellipsis").font(.system(size: 17)).foregroundStyle(Color.t2).frame(width: 30, height: 30)
        }
        .frame(height: 52).padding(.horizontal, 18)
        .background(Color(hex: "#1c1c1f").opacity(0.72).background(.ultraThinMaterial))
        .overlay(alignment: .bottom) { Rectangle().fill(Color.black.opacity(0.45)).frame(height: 0.5) }
    }
}

struct SpecChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 11))
            Text(text).font(.system(size: 11.5, weight: .semibold))
        }
        .foregroundStyle(Color.t2)
        .frame(height: 24).padding(.horizontal, 10)
        .background(Color.card)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.stroke, lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct TabItem: View {
    let label: String
    let active: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text(label)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(active ? Color.t1 : Color.t3)
                .padding(.bottom, 12)
                .padding(.trailing, 22)
            if active {
                Rectangle()
                    .fill(Color.accent)
                    .frame(height: 2)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .padding(.trailing, 22)
            }
        }
    }
}


// MARK: - Real Dependency Card (wired to DependencyViewModel)

struct DependencyCard: View {
    let dep: Dependency
    let bottle: Bottle
    @ObservedObject var depVM: DependencyViewModel

    private var isInstalling: Bool { depVM.installingId == dep.id }
    private var isInstalled: Bool { depVM.isInstalled(dep) }

    private var icon: String {
        switch dep.type {
        case .graphics: return "cube.transparent"
        case .runtime:  return "shippingbox"
        case .font:     return "textformat"
        case .other:    return "puzzlepiece"
        }
    }

    private var gradient: LinearGradient {
        switch dep.type {
        case .graphics: return .init(colors: [Color(hex: "#9a6bff"), Color(hex: "#6f54f0")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .runtime:  return .init(colors: [Color(hex: "#ff8a3d"), Color(hex: "#ff5a52")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .font:     return .init(colors: [Color(hex: "#34c7c0"), Color(hex: "#2aa39c")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .other:    return .init(colors: [Color(hex: "#4aa3ff"), Color(hex: "#2f6bd6")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 11)
                    .fill(gradient)
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(dep.displayName)
                    .font(.system(size: 14.5, weight: .bold))
                    .tracking(-0.1)
                    .foregroundStyle(Color.t1)
                Text(dep.description)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.t2)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            depActionView
        }
        .padding(16)
        .background(Color.card)
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.stroke, lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 13))
    }

    @ViewBuilder
    private var depActionView: some View {
        if isInstalled {
            HStack(spacing: 5) {
                Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                Text("Installed").font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Color.statusGreen)
            .frame(height: 26).padding(.horizontal, 11)
            .background(Color.statusGreen.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 7))
        } else if isInstalling {
            VStack(alignment: .trailing, spacing: 8) {
                Text("Installing…").font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.statusAmber)
                    .frame(height: 26).padding(.horizontal, 11)
                    .background(Color.statusAmber.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 7))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.12)).frame(height: 5)
                        RoundedRectangle(cornerRadius: 3).fill(Color.statusAmber)
                            .frame(width: geo.size.width * CGFloat(depVM.installProgress) / 100, height: 5)
                    }
                }
                .frame(width: 96, height: 5)
            }
        } else {
            Button(action: { Task { await depVM.install(dep, into: bottle) } }) {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.down").font(.system(size: 11, weight: .semibold))
                    Text("Install").font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.t1)
                .frame(height: 26).padding(.horizontal, 11)
                .background(Color.white.opacity(0.10))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.stroke2, lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
            .disabled(depVM.installingId != nil)
        }
    }
}

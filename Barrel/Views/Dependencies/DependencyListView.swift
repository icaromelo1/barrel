import SwiftUI

struct ComponentData: Identifiable {
    let id: String
    let name: String
    let version: String
    let description: String
    let icon: String
    let gradient: LinearGradient
    let state: ComponentState

    enum ComponentState { case installed, installing(Int), available }
}

let sampleComponents: [ComponentData] = [
    ComponentData(id: "dxvk",   name: "DXVK",                version: "v2.4",       description: "Direct3D 9/10/11 translated to Vulkan for native-speed rendering.", icon: "cube.transparent",        gradient: .init(colors: [Color(hex: "#9a6bff"), Color(hex: "#6f54f0")], startPoint: .topLeading, endPoint: .bottomTrailing), state: .installed),
    ComponentData(id: "vkd3d",  name: "VKD3D-Proton",         version: "v2.13",      description: "Direct3D 12 over Vulkan — required by this DX12 bottle.", icon: "cube",                     gradient: .init(colors: [Color(hex: "#4aa3ff"), Color(hex: "#2f6bd6")], startPoint: .topLeading, endPoint: .bottomTrailing), state: .installed),
    ComponentData(id: "vcredist",name: "Visual C++ Redist",   version: "2015–2022",  description: "Microsoft runtime libraries most Windows games link against.", icon: "shippingbox",              gradient: .init(colors: [Color(hex: "#ff8a3d"), Color(hex: "#ff5a52")], startPoint: .topLeading, endPoint: .bottomTrailing), state: .installed),
    ComponentData(id: "dotnet", name: ".NET Desktop Runtime", version: "8.0",        description: "Framework runtime for managed launchers and tools.", icon: "chevron.left.forwardslash.chevron.right", gradient: .init(colors: [Color(hex: "#8b6bff"), Color(hex: "#b06bff")], startPoint: .topLeading, endPoint: .bottomTrailing), state: .installing(64)),
    ComponentData(id: "dx",     name: "DirectX End-User",     version: "Jun 2010",   description: "Legacy D3DX, XAudio and XInput components.", icon: "display",                  gradient: .init(colors: [Color(hex: "#34c7c0"), Color(hex: "#2aa39c")], startPoint: .topLeading, endPoint: .bottomTrailing), state: .available),
    ComponentData(id: "mf",     name: "Media Foundation",     version: "—",          description: "Codecs for in-engine video cutscene playback.", icon: "bolt",                     gradient: .init(colors: [Color(hex: "#ffb340"), Color(hex: "#ff8a3d")], startPoint: .topLeading, endPoint: .bottomTrailing), state: .available),
]

struct DependencyListView: View {
    var body: some View {
        ZStack {
            Color.contentBg.ignoresSafeArea()

            VStack(spacing: 0) {
                DependencyToolbar()

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
                            Text("Gaming")
                                .font(.system(size: 23, weight: .bold))
                                .tracking(-0.5)
                                .foregroundStyle(Color.t1)

                            HStack(spacing: 8) {
                                SpecChip(icon: "display", text: "DirectX 12")
                                SpecChip(icon: "square.stack.3d.up", text: "Windows 11 · 64-bit")
                                SpecChip(icon: "cpu", text: "Wine 9.0")
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
                            Text("4 of 6 installed · last sync 2m ago")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.t3)
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            ForEach(sampleComponents) { c in
                                ComponentCard(component: c)
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
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "sidebar.left").font(.system(size: 17)).foregroundStyle(Color.t2).frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text("Gaming").font(.system(size: 15, weight: .semibold)).tracking(-0.1).foregroundStyle(Color.t1)
                Text("Bottle · 6 games").font(.system(size: 12, weight: .medium)).foregroundStyle(Color.t3)
            }
            Spacer()
            Image(systemName: "folder").font(.system(size: 16)).foregroundStyle(Color.t2).frame(width: 30, height: 30)
            Image(systemName: "ellipsis").font(.system(size: 17)).foregroundStyle(Color.t2).frame(width: 30, height: 30)
            HStack(spacing: 7) {
                Image(systemName: "plus").font(.system(size: 13, weight: .semibold))
                Text("Add Game").font(.system(size: 13, weight: .semibold)).tracking(-0.1)
            }
            .foregroundStyle(.white).frame(height: 30).padding(.horizontal, 14)
            .background(LinearGradient.accent).clipShape(RoundedRectangle(cornerRadius: 8))
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

struct ComponentCard: View {
    let component: ComponentData

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 11)
                    .fill(component.gradient)
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                Image(systemName: component.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(component.name)
                        .font(.system(size: 14.5, weight: .bold))
                        .tracking(-0.1)
                        .foregroundStyle(Color.t1)
                    Text(component.version)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.t3)
                        .padding(.horizontal, 6).padding(.vertical, 1)
                        .background(Color.white.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                Text(component.description)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.t2)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            ComponentActionView(state: component.state)
        }
        .padding(16)
        .background(Color.card)
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.stroke, lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 13))
    }
}

struct ComponentActionView: View {
    let state: ComponentData.ComponentState

    var body: some View {
        switch state {
        case .installed:
            HStack(spacing: 5) {
                Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                Text("Installed").font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Color.statusGreen)
            .frame(height: 26).padding(.horizontal, 11)
            .background(Color.statusGreen.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 7))

        case .installing(let pct):
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 5) {
                    Text("Installing… \(pct)%").font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.statusAmber)
                .frame(height: 26).padding(.horizontal, 11)
                .background(Color.statusAmber.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 7))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.12)).frame(height: 5)
                        RoundedRectangle(cornerRadius: 3).fill(Color.statusAmber)
                            .frame(width: geo.size.width * CGFloat(pct) / 100, height: 5)
                    }
                }
                .frame(width: 96, height: 5)
            }

        case .available:
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
    }
}

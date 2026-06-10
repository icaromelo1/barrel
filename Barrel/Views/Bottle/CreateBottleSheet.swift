import SwiftUI

struct CreateBottleSheet: View {
    @Binding var isPresented: Bool
    @State private var name = "RPG Vault"
    @State private var selectedAPI: GraphicsAPI = .dx12
    @State private var selectedPreset: GamePreset = .rpg

    enum GraphicsAPI: CaseIterable {
        case dx12, dx11, opengl
        var label: String { switch self { case .dx12: "DirectX 12"; case .dx11: "DirectX 11"; case .opengl: "OpenGL" } }
        var sublabel: String { switch self { case .dx12: "VKD3D · modern"; case .dx11: "DXVK · broad"; case .opengl: "Native · legacy" } }
        var icon: String { switch self { case .dx12: "display"; case .dx11: "display"; case .opengl: "cube" } }
    }

    enum GamePreset: CaseIterable {
        case fps, rpg, strategy
        var label: String { switch self { case .fps: "FPS"; case .rpg: "RPG"; case .strategy: "Strategy" } }
        var subtitle: String { switch self { case .fps: "Low latency"; case .rpg: "Large prefix"; case .strategy: "Multi-core" } }
        var icon: String { switch self { case .fps: "scope"; case .rpg: "shield"; case .strategy: "flag" } }
        var gradient: LinearGradient {
            switch self {
            case .fps:      .init(colors: [Color(hex: "#ff7a3d"), Color(hex: "#ff4d6d")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .rpg:      .init(colors: [Color(hex: "#9a6bff"), Color(hex: "#6f54f0")], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .strategy: .init(colors: [Color(hex: "#4aa3ff"), Color(hex: "#34c7c0")], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("New Bottle")
                    .font(.system(size: 19, weight: .bold))
                    .tracking(-0.4)
                    .foregroundStyle(Color.t1)

                Text("An isolated Windows environment that keeps each game's files and settings apart.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.t2)
                    .padding(.top, 4)

                // name field
                Text("Name")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.t2)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                HStack {
                    TextField("", text: $name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.t1)
                        .textFieldStyle(.plain)
                }
                .frame(height: 38)
                .padding(.horizontal, 13)
                .background(Color.black.opacity(0.28))
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color(hex: "#8b6bff"), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .shadow(color: Color(hex: "#8b6bff").opacity(0.25), radius: 3)

                // graphics API
                Text("Graphics API")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.t2)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                HStack(spacing: 9) {
                    ForEach(GraphicsAPI.allCases, id: \.self) { api in
                        APICard(api: api, selected: selectedAPI == api)
                            .onTapGesture { selectedAPI = api }
                    }
                }

                // quick setup
                Text("Quick setup")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.t2)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                HStack(spacing: 9) {
                    ForEach(GamePreset.allCases, id: \.self) { preset in
                        PresetCard(preset: preset, selected: selectedPreset == preset)
                            .onTapGesture { selectedPreset = preset }
                    }
                }
            }
            .padding(28)

            // footer
            HStack {
                Text("Stored in ~/Library/Bottles · ~480 MB")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.t3)
                Spacer()
                Button("Cancel") { isPresented = false }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.t1)
                    .frame(height: 32)
                    .padding(.horizontal, 16)
                    .background(Color.white.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.stroke2, lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .buttonStyle(.plain)

                Button(action: { isPresented = false }) {
                    HStack(spacing: 7) {
                        Image(systemName: "plus").font(.system(size: 12, weight: .semibold))
                        Text("Create Bottle").font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(height: 32)
                    .padding(.horizontal, 18)
                    .background(LinearGradient.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: Color(hex: "#7c5cff").opacity(0.4), radius: 8, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            .blendMode(.plusLighter)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(Color.black.opacity(0.22))
            .overlay(alignment: .top) {
                Rectangle().fill(Color.stroke).frame(height: 0.5)
            }
        }
        .background(
            Color(hex: "#2c2c30").opacity(0.9)
                .background(.ultraThickMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.stroke2, lineWidth: 0.5)
        )
        .frame(width: 560)
        .shadow(color: .black.opacity(0.6), radius: 70, y: 30)
    }
}

struct APICard: View {
    let api: CreateBottleSheet.GraphicsAPI
    let selected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selected ? Color(hex: "#8b6bff").opacity(0.3) : Color.white.opacity(0.08))
                            .frame(width: 28, height: 28)
                        Image(systemName: api.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    }
                    Text(api.label)
                        .font(.system(size: 13.5, weight: .bold))
                        .tracking(-0.1)
                        .foregroundStyle(Color.t1)
                    Text(api.sublabel)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.t2)
                }
                .padding(13)

                if selected {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#8b6bff"))
                        .padding(11)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            selected
                ? LinearGradient.accentSoft
                : LinearGradient(colors: [Color.white.opacity(0.045)], startPoint: .top, endPoint: .bottom)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11)
                .stroke(
                    selected ? Color(hex: "#8b6bff").opacity(0.55) : Color.stroke,
                    lineWidth: selected ? 1 : 0.5
                )
                .overlay(
                    selected ? RoundedRectangle(cornerRadius: 11).stroke(Color(hex: "#8b6bff").opacity(0.4), lineWidth: 0.5) : nil
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 11))
    }
}

struct PresetCard: View {
    let preset: CreateBottleSheet.GamePreset
    let selected: Bool

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(preset.gradient)
                    .frame(width: 36, height: 36)
                Image(systemName: preset.icon)
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
            }
            Text(preset.label)
                .font(.system(size: 12.5, weight: .bold))
                .foregroundStyle(selected ? .white : Color.t1)
            Text(preset.subtitle)
                .font(.system(size: 10))
                .foregroundStyle(Color.t3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(selected ? Color.white.opacity(0.08) : Color.white.opacity(0.045))
        .overlay(
            RoundedRectangle(cornerRadius: 11)
                .stroke(selected ? Color.stroke3 : Color.stroke, lineWidth: selected ? 1 : 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 11))
    }
}

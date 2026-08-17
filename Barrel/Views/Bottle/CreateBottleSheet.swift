import SwiftUI

struct CreateBottleSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var bottleVM: BottleViewModel

    @State private var name = ""
    @State private var selectedPreset: BottlePreset = .steam
    @State private var showAdvanced = false
    @State private var selectedRenderer: Renderer = .dxvk
    @State private var esync = true
    @State private var msync = true
    @State private var errorMessage: String?

    // BottlePreset is now defined in Bottle.swift (top-level)

    var body: some View {
        VStack(spacing: 0) {
            // Content
            VStack(alignment: .leading, spacing: 0) {
                Text("New Bottle")
                    .font(.system(size: 19, weight: .bold))
                    .tracking(-0.4)
                    .foregroundStyle(Color.t1)

                Text("An isolated Windows environment for your games.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.t2)
                    .padding(.top, 4)

                // Name
                Text("Name")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.t2)
                    .padding(.top, 22)
                    .padding(.bottom, 8)

                HStack {
                    TextField("Bottle name", text: $name)
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
                .shadow(color: Color(hex: "#8b6bff").opacity(0.2), radius: 3)

                // Preset
                Text("Setup")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.t2)
                    .padding(.top, 22)
                    .padding(.bottom, 10)

                VStack(spacing: 8) {
                    ForEach(BottlePreset.allCases, id: \.self) { preset in
                        PresetRow(preset: preset, selected: selectedPreset == preset)
                            .onTapGesture {
                                selectedPreset = preset
                                if name.isEmpty || BottlePreset.allCases.contains(where: { $0.defaultName == name }) {
                                    name = preset.defaultName
                                }
                            }
                    }
                }

                // Advanced toggle
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showAdvanced.toggle() } }) {
                    HStack(spacing: 6) {
                        Image(systemName: showAdvanced ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Advanced options")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color.t3)
                }
                .buttonStyle(.plain)
                .padding(.top, 16)

                if showAdvanced {
                    VStack(alignment: .leading, spacing: 10) {
                        // Renderer picker
                        HStack {
                            Text("Renderer")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.t2)
                                .frame(width: 80, alignment: .leading)
                            Picker("", selection: $selectedRenderer) {
                                Text("DXVK (DX9/10/11 → Vulkan)").tag(Renderer.dxvk)
                                Text("OpenGL (legacy)").tag(Renderer.gl)
                                // D3DMetal (DX12) not yet implemented — needs VKD3D-Proton + MoltenVK.
                                // Renderer.metal case stays in the model so existing bottles keep decoding.
                            }
                            .pickerStyle(.menu)
                            .tint(Color.t1)
                        }

                        Toggle(isOn: $esync) {
                            Text("ESync  ")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.t2)
                        }
                        .toggleStyle(.switch)
                        .tint(Color.accent)

                        Toggle(isOn: $msync) {
                            Text("MSync  ")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.t2)
                        }
                        .toggleStyle(.switch)
                        .tint(Color.accent)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.stroke, lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Error
                if let err = errorMessage ?? bottleVM.error {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.statusAmber)
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.statusAmber)
                    }
                    .padding(.top, 12)
                }
            }
            .padding(28)

            // Footer
            HStack {
                Text(StorageManager.shared.isExternalSSDMounted ? "SSD externo · /barrel-data/bottles" : "~/Library/Barrel/bottles")
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

                Button(action: createBottle) {
                    HStack(spacing: 7) {
                        if bottleVM.isLoading {
                            ProgressView().progressViewStyle(.circular).scaleEffect(0.7).tint(.white)
                            Text("Creating…")
                        } else {
                            Image(systemName: "plus").font(.system(size: 12, weight: .semibold))
                            Text("Create Bottle")
                        }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(height: 32)
                    .padding(.horizontal, 18)
                    .background(LinearGradient.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: Color(hex: "#7c5cff").opacity(0.4), radius: 8, y: 2)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.3), lineWidth: 0.5).blendMode(.plusLighter))
                }
                .buttonStyle(.plain)
                .disabled(bottleVM.isLoading || displayName.isEmpty)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(Color.black.opacity(0.22))
            .overlay(alignment: .top) { Rectangle().fill(Color.stroke).frame(height: 0.5) }
        }
        .background(Color(hex: "#2c2c30").opacity(0.9).background(.ultraThickMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.stroke2, lineWidth: 0.5))
        .frame(width: 520)
        .shadow(color: .black.opacity(0.6), radius: 70, y: 30)
        .onAppear {
            name = selectedPreset.defaultName
        }
    }

    private var displayName: String { name.trimmingCharacters(in: .whitespaces) }

    private func createBottle() {
        errorMessage = nil
        let renderer = showAdvanced ? selectedRenderer : selectedPreset.defaultRenderer
        let config = BottleConfig(arch: .win64, renderer: renderer, esync: esync, msync: msync)
        Task {
            if await bottleVM.createWithPreset(name: displayName, config: config, preset: selectedPreset) != nil {
                isPresented = false
            } else {
                errorMessage = bottleVM.error ?? "Falha ao criar garrafa. Wine instalado?"
            }
        }
    }
}

// MARK: - Preset row

struct PresetRow: View {
    let preset: BottlePreset
    let selected: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(
                        colors: [Color(hex: preset.gradient.start), Color(hex: preset.gradient.end)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 40, height: 40)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                Image(systemName: preset.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(preset.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.t1)
                Text(preset.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.t2)
            }

            Spacer()

            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.accent)
            } else {
                Circle()
                    .stroke(Color.stroke2, lineWidth: 1.5)
                    .frame(width: 18, height: 18)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(selected ? Color(hex: "#8b6bff").opacity(0.10) : Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(selected ? Color(hex: "#8b6bff").opacity(0.4) : Color.stroke, lineWidth: selected ? 1 : 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

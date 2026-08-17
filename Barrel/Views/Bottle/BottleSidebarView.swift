import SwiftUI

struct SidebarBottleData: Identifiable {
    let id: String
    let name: String
    let api: String
    let color: Color
    let count: Int
    var initMessage: String? = nil  // non-nil = bottle is initializing
}

struct BottleSidebarView: View {
    @Binding var selectedBottle: String?
    @Binding var searchText: String
    @EnvironmentObject private var bottleVM: BottleViewModel
    @EnvironmentObject private var wineSetup: WineSetupViewModel
    @State private var showCreateBottle = false
    @State private var bottleToDelete: Bottle? = nil

    private var displayBottles: [SidebarBottleData] {
        bottleVM.bottles.map { b in
            let api: String
            switch b.config.renderer {
            case .dxvk:  api = "DXVK"
            case .metal: api = "Metal"
            case .gl:    api = "OpenGL"
            }
            let initMsg = bottleVM.initMessages[b.id]
            return SidebarBottleData(
                id: b.id.uuidString,
                name: b.name,
                api: api,
                color: Color(hex: "#8b6bff"),
                count: b.games.count,
                initMessage: initMsg
            )
        }
    }

    private var totalGames: Int {
        bottleVM.bottles.reduce(0) { $0 + $1.games.count }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Search bar
                    HStack(spacing: 7) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.t3)
                        TextField("Search games", text: $searchText)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.t1)
                            .textFieldStyle(.plain)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.t3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(height: 30)
                    .padding(.horizontal, 9)
                    .background(Color.white.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.stroke, lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .padding(.bottom, 12)

                    // Fixed rows
                    SidebarRow(
                        icon: "square.grid.2x2.fill",
                        label: "All Games",
                        count: totalGames > 0 ? "\(totalGames)" : nil,
                        selected: selectedBottle == nil
                    )
                    .onTapGesture { selectedBottle = nil }

                    // Bottles section
                    Text("Bottles")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(Color.t3)
                        .textCase(.uppercase)
                        .padding(.horizontal, 10)
                        .padding(.top, 14)
                        .padding(.bottom, 5)

                    if bottleVM.isLoading {
                        HStack {
                            ProgressView().scaleEffect(0.7)
                            Text("Loading…")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.t3)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                    } else if displayBottles.isEmpty {
                        // Empty state
                        VStack(spacing: 8) {
                            Image(systemName: "flask")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.t4)
                            Text("No bottles yet")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.t3)
                            Text("Create a bottle to get started")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.t4)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        ForEach(displayBottles) { bottle in
                            SidebarBottleRow(bottle: bottle, selected: selectedBottle == bottle.id)
                                .onTapGesture { selectedBottle = bottle.id }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        bottleToDelete = bottleVM.bottles.first { $0.id.uuidString == bottle.id }
                                    } label: {
                                        Label("Delete Bottle", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }

            Divider().opacity(0.15)

            // Footer: New Bottle + Wine status + Settings
            VStack(spacing: 0) {
                // Download progress bar (visible only while downloading/extracting)
                if wineSetup.state.isInProgress {
                    WineDownloadBanner(vm: wineSetup)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 8)
                }

                HStack(spacing: 8) {
                    Button(action: { showCreateBottle = true }) {
                        HStack(spacing: 7) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 14))
                            Text("New Bottle")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(Color.t2)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    WineStatusBadge(vm: wineSetup)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .sheet(isPresented: $showCreateBottle) {
            CreateBottleSheet(isPresented: $showCreateBottle, bottleVM: bottleVM)
        }
        .confirmationDialog(
            "Delete \"\(bottleToDelete?.name ?? "")\"?",
            isPresented: Binding(get: { bottleToDelete != nil }, set: { if !$0 { bottleToDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let bottle = bottleToDelete {
                    if selectedBottle == bottle.id.uuidString { selectedBottle = nil }
                    Task { await bottleVM.delete(bottle) }
                }
                bottleToDelete = nil
            }
            Button("Cancel", role: .cancel) { bottleToDelete = nil }
        } message: {
            Text("This deletes the entire Wine prefix, including all installed apps and games inside it. This cannot be undone.")
        }
        .background(
            ZStack {
                WallpaperView()
                Color(hex: "#201e26").opacity(0.62)
            }
            .ignoresSafeArea()
        )
        .background(.ultraThinMaterial)
        .overlay(alignment: .trailing) {
            Rectangle().fill(Color.black.opacity(0.4)).frame(width: 0.5)
        }
    }
}

// MARK: - Wine status badge (dot + label)

struct WineStatusBadge: View {
    @ObservedObject var vm: WineSetupViewModel

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(Color.t4)
        }
        .onTapGesture {
            if case .failed = vm.state {
                Task { await vm.retry() }
            }
        }
    }

    private var dotColor: Color {
        switch vm.state {
        case .ready:                        return Color.statusGreen
        case .downloading, .extracting,
             .checking:                     return Color.statusAmber
        case .failed:                       return Color.statusRed
        case .idle:                         return Color.t4
        }
    }

    private var label: String {
        switch vm.state {
        case .ready:        return "Wine ready"
        case .checking:     return "Checking..."
        case .downloading:  return "Downloading..."
        case .extracting:   return "Extracting..."
        case .failed:       return "Tap to retry"
        case .idle:         return "Wine missing"
        }
    }
}

// MARK: - Download progress banner

struct WineDownloadBanner: View {
    @ObservedObject var vm: WineSetupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(vm.progressMessage)
                    .font(.system(size: 10.5))
                    .foregroundStyle(Color.t3)
                    .lineLimit(1)
                Spacer()
                if vm.downloadProgress > 0 {
                    Text("\(Int(vm.downloadProgress * 100))%")
                        .font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .foregroundStyle(Color.t4)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient.accent)
                        .frame(width: geo.size.width * vm.downloadProgress, height: 3)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Sidebar rows

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
        .background(RoundedRectangle(cornerRadius: 7).fill(selected ? Color.white.opacity(0.10) : .clear))
    }
}

struct SidebarBottleRow: View {
    let bottle: SidebarBottleData
    let selected: Bool

    private var isInitializing: Bool { bottle.initMessage != nil }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "flask")
                .font(.system(size: 15))
                .frame(width: 19)
                .foregroundStyle(selected ? Color.white : bottle.color)
                .opacity(isInitializing ? 0.5 : 1)

            VStack(alignment: .leading, spacing: 1) {
                Text(bottle.name)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(Color.t1)
                if let msg = bottle.initMessage {
                    Text(msg)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.statusAmber)
                        .lineLimit(1)
                }
            }

            Spacer()

            if isInitializing {
                ProgressView()
                    .scaleEffect(0.55)
                    .frame(width: 14)
            } else {
                Text(bottle.api)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(selected ? Color.white.opacity(0.7) : Color.t3)
            }
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
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(hex: "#8b6bff").opacity(0.35), lineWidth: 0.5))
                } else {
                    RoundedRectangle(cornerRadius: 7).fill(Color.clear)
                }
            }
        )
    }
}

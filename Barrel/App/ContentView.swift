import SwiftUI

enum ContentTab {
    case library, dependencies
}

struct ContentView: View {
    @StateObject private var bottleVM = BottleViewModel()
    @StateObject private var libraryVM = LibraryViewModel()
    @StateObject private var wineSetup = WineSetupViewModel()

    @State private var selectedBottleId: String? = nil
    @State private var searchText: String = ""
    @State private var contentTab: ContentTab = .library

    private var selectedBottle: Bottle? {
        guard let id = selectedBottleId else { return nil }
        return bottleVM.bottles.first { $0.id.uuidString == id }
    }

    var body: some View {
        NavigationSplitView {
            BottleSidebarView(selectedBottle: $selectedBottleId, searchText: $searchText)
                .environmentObject(bottleVM)
                .environmentObject(wineSetup)
                .navigationSplitViewColumnWidth(min: 220, ideal: 248, max: 300)
        } detail: {
            Group {
                if contentTab == .dependencies, let bottle = selectedBottle {
                    DependencyListView(bottle: bottle, onSwitchToGames: { contentTab = .library })
                } else {
                    LibraryView(
                        selectedBottle: $selectedBottleId,
                        libraryVM: libraryVM,
                        bottleVM: bottleVM,
                        searchText: searchText,
                        onOpenComponents: selectedBottle != nil ? { contentTab = .dependencies } : nil
                    )
                }
            }
        }
        .onChange(of: selectedBottleId) { newValue in
            if newValue == nil { contentTab = .library }
        }
        .task { await bottleVM.load() }
        .task { await libraryVM.load() }
        .task { await wineSetup.setup() }
        .frame(minWidth: 1000, minHeight: 640)
        .preferredColorScheme(.dark)
    }
}

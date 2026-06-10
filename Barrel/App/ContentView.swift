import SwiftUI

struct ContentView: View {
    @StateObject private var bottleVM = BottleViewModel()
    @StateObject private var libraryVM = LibraryViewModel()
    @StateObject private var wineSetup = WineSetupViewModel()

    @State private var selectedBottleId: String? = nil

    var body: some View {
        NavigationSplitView {
            BottleSidebarView(selectedBottle: $selectedBottleId)
                .environmentObject(bottleVM)
                .environmentObject(wineSetup)
                .navigationSplitViewColumnWidth(min: 220, ideal: 248, max: 300)
        } detail: {
            LibraryView(
                selectedBottle: $selectedBottleId,
                libraryVM: libraryVM,
                bottleVM: bottleVM
            )
        }
        .task { await bottleVM.load() }
        .task { await libraryVM.load() }
        .task { await wineSetup.setup() }
        .frame(minWidth: 1000, minHeight: 640)
        .preferredColorScheme(.dark)
    }
}

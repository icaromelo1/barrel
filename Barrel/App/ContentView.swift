import SwiftUI

enum AppRoute: Hashable {
    case library
    case dependencies
    case gameDetail
}

struct ContentView: View {
    @State private var selectedBottle: String? = nil
    @State private var route: AppRoute = .library

    var body: some View {
        HStack(spacing: 0) {
            BottleSidebarView(selectedBottle: $selectedBottle)

            ZStack {
                switch route {
                case .library:
                    LibraryView(selectedBottle: $selectedBottle)
                case .dependencies:
                    DependencyListView()
                case .gameDetail:
                    GameDetailView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(WallpaperView().ignoresSafeArea())
        .frame(minWidth: 1100, minHeight: 700)
        .preferredColorScheme(.dark)
    }
}

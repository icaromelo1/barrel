import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            Text("Garrafas")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } detail: {
            Text("Selecione uma garrafa")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

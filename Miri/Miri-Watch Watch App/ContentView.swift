import SwiftUI

struct ContentView: View {
    @StateObject private var store = WatchShiftStore()

    var body: some View {
        NavigationStack {
            WatchGlanceView()
        }
        .environmentObject(store)
    }
}

#Preview {
    ContentView()
}

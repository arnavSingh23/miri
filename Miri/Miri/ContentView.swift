import SwiftUI

struct ContentView: View {
    @StateObject private var store = ShiftStore()

    var body: some View {
        Group {
            if store.hasStartedShift {
                RootTabView()
            } else {
                ShiftSetupView()
            }
        }
            .environmentObject(store)
    }
}

#Preview {
    ContentView()
}

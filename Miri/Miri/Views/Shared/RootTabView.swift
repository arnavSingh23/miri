import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NowView()
                .tabItem {
                    Label("Now", systemImage: "clock")
                }

            PatientsView()
                .tabItem {
                    Label("Patients", systemImage: "person.2")
                }

            QuickAddView()
                .tabItem {
                    Label("Quick Add", systemImage: "plus.circle")
                }

            SummaryView()
                .tabItem {
                    Label("Summary", systemImage: "checklist")
                }
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(ShiftStore())
}

import SwiftUI

struct StartShiftView: View {
    var body: some View {
        ShiftSetupView()
    }
}

#Preview {
    StartShiftView()
        .environmentObject(ShiftStore())
}

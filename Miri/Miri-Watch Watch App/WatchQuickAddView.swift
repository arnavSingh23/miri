import SwiftUI

struct WatchQuickAddView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "mic.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.green)
                .frame(width: 76, height: 76)
                .background(Color.white.opacity(0.12))
                .clipShape(Circle())

            Text("Voice capture later")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Quick add will stay lightweight on Watch.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 8)
        .navigationTitle("Quick Add")
    }
}

#Preview {
    WatchQuickAddView()
}

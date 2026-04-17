import SwiftUI

struct WatchGlanceView: View {
    @EnvironmentObject var store: WatchShiftStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                header
                counts

                if let topTask = store.topTask {
                    NavigationLink {
                        WatchTaskDetailView(taskID: topTask.id)
                    } label: {
                        topTaskCard(topTask)
                    }
                    .buttonStyle(.plain)
                } else {
                    emptyCard
                }

                NavigationLink {
                    WatchQuickAddView()
                } label: {
                    Label("Quick Add", systemImage: "mic.fill")
                        .font(.footnote)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Miri")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Miri")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Shift glance")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var counts: some View {
        HStack(spacing: 6) {
            countCard(title: "Attention", count: store.needsAttention.count, color: .red)
            countCard(title: "Soon", count: store.comingUpSoon.count, color: .yellow)
        }
    }

    private func countCard(title: String, count: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(count)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(color)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func topTaskCard(_ task: WatchTask) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(priorityLabel(for: task))
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(priorityColor(for: task))

            Text(task.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            HStack {
                Text("Room \(task.roomLabel)")
                Spacer()
                Text(timingLabel(for: task))
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var emptyCard: some View {
        Text("Nothing urgent right now")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color.white.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func priorityLabel(for task: WatchTask) -> String {
        switch task.priority {
        case .urgent:
            return "Needs Attention"
        case .soon:
            return "Coming Up Soon"
        case .followUp:
            return "Follow-Up"
        case .routine:
            return "Routine"
        }
    }

    private func priorityColor(for task: WatchTask) -> Color {
        switch task.priority {
        case .urgent:
            return .red
        case .soon:
            return .yellow
        case .followUp:
            return .blue
        case .routine:
            return .green
        }
    }

    private func timingLabel(for task: WatchTask) -> String {
        guard let dueAt = task.dueAt else {
            return "No time"
        }

        let minutes = Int(dueAt.timeIntervalSince(Date()) / 60)

        if minutes <= 0 {
            return "Due now"
        }

        return "In \(minutes)m"
    }
}

#Preview {
    NavigationStack {
        WatchGlanceView()
            .environmentObject(WatchShiftStore())
    }
}

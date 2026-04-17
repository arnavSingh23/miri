import SwiftUI

struct WatchTaskDetailView: View {
    @EnvironmentObject var store: WatchShiftStore
    let taskID: WatchTask.ID

    var body: some View {
        ScrollView {
            if let task = store.task(for: taskID) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(priorityLabel(for: task))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(priorityColor(for: task))

                    Text(task.title)
                        .font(.headline)
                        .lineLimit(3)

                    Text("Room \(task.roomLabel)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if task.isPinned {
                        Label("Pinned", systemImage: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }

                    Button("Mark Done") {
                        store.markDone(taskID)
                    }
                    .tint(.green)

                    Button("Snooze 15m") {
                        store.snooze(taskID, minutes: 15)
                    }
                    .tint(.blue)

                    Button(task.isPinned ? "Unpin" : "Pin") {
                        store.pin(taskID)
                    }
                    .tint(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Task no longer active")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Task")
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
}

#Preview {
    NavigationStack {
        WatchTaskDetailView(taskID: WatchTask.demoPainTaskID)
            .environmentObject(WatchShiftStore())
    }
}

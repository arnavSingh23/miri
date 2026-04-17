import Foundation
import Combine

@MainActor
final class WatchShiftStore: ObservableObject {
    @Published var tasks: [WatchTask] = WatchTask.demoTasks

    var needsAttention: [WatchTask] {
        let now = Date()

        return activeTasks
            .filter { task in
                task.isPinned ||
                task.priority == .urgent ||
                task.dueAt.map { $0 <= now } == true
            }
            .sorted { sortKey($0) < sortKey($1) }
    }

    var comingUpSoon: [WatchTask] {
        let now = Date()
        let soon = now.addingTimeInterval(60 * 60)

        return activeTasks
            .filter { task in
                guard !needsAttention.contains(where: { $0.id == task.id }),
                      let dueAt = task.dueAt else {
                    return false
                }

                return dueAt > now && dueAt <= soon
            }
            .sorted { sortKey($0) < sortKey($1) }
    }

    var topTask: WatchTask? {
        needsAttention.first ?? comingUpSoon.first ?? activeTasks.first
    }

    func markDone(_ taskID: WatchTask.ID) {
        update(taskID) { task in
            task.status = .done
            task.snoozedUntil = nil
        }
    }

    func snooze(_ taskID: WatchTask.ID, minutes: Int) {
        update(taskID) { task in
            task.status = .snoozed
            task.snoozedUntil = Date().addingTimeInterval(TimeInterval(minutes * 60))
        }
    }

    func pin(_ taskID: WatchTask.ID) {
        update(taskID) { task in
            task.isPinned.toggle()
        }
    }

    func task(for id: WatchTask.ID) -> WatchTask? {
        tasks.first { $0.id == id }
    }

    private var activeTasks: [WatchTask] {
        let now = Date()

        return tasks.filter { task in
            guard task.status != .done else {
                return false
            }

            if task.status == .snoozed, let snoozedUntil = task.snoozedUntil {
                return snoozedUntil <= now
            }

            return true
        }
    }

    private func update(_ taskID: WatchTask.ID, mutate: (inout WatchTask) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else {
            return
        }

        mutate(&tasks[index])
    }

    private func sortKey(_ task: WatchTask) -> Date {
        task.dueAt ?? task.createdAt
    }
}

struct WatchTask: Identifiable, Hashable {
    static let demoPainTaskID = UUID(uuidString: "00000000-0000-0000-0000-000000000414")!
    static let demoVitalsTaskID = UUID(uuidString: "00000000-0000-0000-0000-000000000402")!
    static let demoIntakeTaskID = UUID(uuidString: "00000000-0000-0000-0000-000000000408")!

    enum Priority {
        case urgent
        case soon
        case followUp
        case routine
    }

    enum Status {
        case pending
        case done
        case snoozed
    }

    let id: UUID
    var title: String
    var roomLabel: String
    var priority: Priority
    var status: Status
    var createdAt: Date
    var dueAt: Date?
    var snoozedUntil: Date?
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        title: String,
        roomLabel: String,
        priority: Priority,
        status: Status = .pending,
        createdAt: Date = Date(),
        dueAt: Date? = nil,
        snoozedUntil: Date? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.roomLabel = roomLabel
        self.priority = priority
        self.status = status
        self.createdAt = createdAt
        self.dueAt = dueAt
        self.snoozedUntil = snoozedUntil
        self.isPinned = isPinned
    }

    static var demoTasks: [WatchTask] {
        let now = Date()

        return [
            WatchTask(
                id: demoPainTaskID,
                title: "Recheck pain score",
                roomLabel: "414",
                priority: .urgent,
                dueAt: now.addingTimeInterval(-4 * 60),
                isPinned: true
            ),
            WatchTask(
                id: demoVitalsTaskID,
                title: "Repeat vitals",
                roomLabel: "402",
                priority: .soon,
                dueAt: now.addingTimeInterval(18 * 60)
            ),
            WatchTask(
                id: demoIntakeTaskID,
                title: "Check oral intake",
                roomLabel: "408",
                priority: .followUp,
                dueAt: now.addingTimeInterval(45 * 60)
            )
        ]
    }
}

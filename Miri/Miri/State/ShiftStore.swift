import Foundation
import SwiftUI
import Combine

@MainActor
final class ShiftStore: ObservableObject {
    @Published var patients: [Patient] = []
    @Published var tasks: [ShiftTask] = []
    @Published var hasStartedShift: Bool = false
    @Published var nurseName: String = "Mariana"
    @Published var unitName: String = ""
    @Published var recentlyAddedTaskID: UUID?
    @Published var resurfacedTaskID: UUID?
    @Published var duplicateTaskID: UUID?

    init() {
        if !loadSavedState() {
            loadMockData()
        }
    }

    var needsAttention: [ShiftTask] {
        let now = Date()
        let tasks = activeTasks(at: now)

        return tasks
            .filter { task in
                task.dueAt.map { $0 <= now } == true ||
                (task.isPinned && task.isActionableNow)
            }
            .sorted { attentionOrder($0, $1, now: now) }
    }

    var comingUpSoon: [ShiftTask] {
        let now = Date()
        let attentionIDs = Set(needsAttention.map(\.id))

        return activeTasks
            .filter { task in
                guard !attentionIDs.contains(task.id),
                      let dueAt = task.dueAt else {
                    return false
                }

                return dueAt > now
            }
            .sorted { comingUpOrder($0, $1, now: now) }
    }

    var unresolvedFollowUps: [ShiftTask] {
        activeTasks
            .filter { task in
                task.dueAt == nil &&
                (task.priority == .followUp || task.category == .followUp)
            }
            .sorted(by: baselineOrder)
    }

    func loadMockData() {
        patients = MockSeed.patients
        tasks = normalizedTasks(MockSeed.tasks)
        recentlyAddedTaskID = nil
        resurfacedTaskID = nil
        duplicateTaskID = nil
        saveState()
    }

    func startShift() {
        hasStartedShift = true
        saveState()
    }

    func endShift() {
        hasStartedShift = false
        saveState()
    }

    func resetDemoData() {
        patients = MockSeed.patients
        tasks = normalizedTasks(MockSeed.tasks)
        hasStartedShift = false
        nurseName = "Mariana"
        unitName = ""
        recentlyAddedTaskID = nil
        resurfacedTaskID = nil
        duplicateTaskID = nil
        saveState()
    }

    func configureShift(name: String, unit: String, rooms: [(room: String, patient: String?)]) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()

        nurseName = trimmedName.isEmpty ? "Mariana" : trimmedName
        unitName = trimmedUnit
        patients = rooms
            .map { room, patient in
                (
                    room: room.trimmingCharacters(in: .whitespacesAndNewlines),
                    patient: patient?.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            .filter { !$0.room.isEmpty }
            .map { room, patient in
                let patientName = patient ?? ""

                return Patient(
                    name: patientName.isEmpty ? "Name pending" : patientName,
                    room: room,
                    status: .stable,
                    lastSeen: now,
                    pendingTaskCount: 0
                )
            }
        tasks = []
        hasStartedShift = true
        recentlyAddedTaskID = nil
        resurfacedTaskID = nil
        duplicateTaskID = nil
        saveState()
    }

    func clearAllTasks() {
        tasks = []
        recentlyAddedTaskID = nil
        resurfacedTaskID = nil
        duplicateTaskID = nil
        saveState()
    }

    func seedUrgentDemoState() {
        let now = Date()
        let primaryPatient = patients.first
        let secondPatient = patients.dropFirst().first
        let thirdPatient = patients.dropFirst(2).first

        tasks = [
            ShiftTask(
                patientID: primaryPatient?.id,
                roomLabel: primaryPatient?.room ?? "Unassigned",
                patientName: primaryPatient?.name,
                title: "Recheck pain score",
                detail: "Follow up after recent PRN medication.",
                category: .followUp,
                priority: .urgent,
                createdAt: now,
                dueAt: now.addingTimeInterval(-6 * 60),
                isPinned: true
            ),
            ShiftTask(
                patientID: secondPatient?.id,
                roomLabel: secondPatient?.room ?? "Unassigned",
                patientName: secondPatient?.name,
                title: "Repeat vitals",
                detail: "Trend before next round.",
                category: .vitals,
                priority: .soon,
                createdAt: now,
                dueAt: now.addingTimeInterval(15 * 60),
                repeatIntervalMinutes: 60
            ),
            ShiftTask(
                patientID: thirdPatient?.id,
                roomLabel: thirdPatient?.room ?? "Unassigned",
                patientName: thirdPatient?.name,
                title: "Confirm lab pickup",
                detail: "Check whether morning labs were collected.",
                category: .lab,
                priority: .followUp,
                createdAt: now,
                dueAt: nil
            )
        ]
        recentlyAddedTaskID = nil
        resurfacedTaskID = nil
        duplicateTaskID = nil
        saveState()
    }

    func seedRoutineDemoState() {
        let now = Date()
        let primaryPatient = patients.first
        let secondPatient = patients.dropFirst().first
        let thirdPatient = patients.dropFirst(2).first

        tasks = [
            ShiftTask(
                patientID: primaryPatient?.id,
                roomLabel: primaryPatient?.room ?? "Unassigned",
                patientName: primaryPatient?.name,
                title: "Document family update",
                detail: "Add a brief note when there is a quiet moment.",
                category: .note,
                priority: .routine,
                createdAt: now,
                dueAt: now.addingTimeInterval(90 * 60)
            ),
            ShiftTask(
                patientID: secondPatient?.id,
                roomLabel: secondPatient?.room ?? "Unassigned",
                patientName: secondPatient?.name,
                title: "Check oral intake",
                detail: "Review hydration before end of shift.",
                category: .hydration,
                priority: .followUp,
                createdAt: now,
                dueAt: nil
            ),
            ShiftTask(
                patientID: thirdPatient?.id,
                roomLabel: thirdPatient?.room ?? "Unassigned",
                patientName: thirdPatient?.name,
                title: "Prepare handoff note",
                detail: "Capture open follow-ups for the next nurse.",
                category: .paperwork,
                priority: .routine,
                createdAt: now,
                dueAt: now.addingTimeInterval(3 * 60 * 60)
            )
        ]
        recentlyAddedTaskID = nil
        resurfacedTaskID = nil
        duplicateTaskID = nil
        saveState()
    }

    @discardableResult
    func addTask(
        title: String,
        detail: String,
        category: TaskCategory,
        priority: TaskPriority,
        patientID: UUID? = nil,
        roomLabel: String = "Unassigned",
        patientName: String? = nil,
        dueAt: Date? = nil,
        repeatIntervalMinutes: Int? = nil
    ) -> ShiftTask {
        let createdAt = Date()
        let normalizedDueAt = normalizedDueAt(
            dueAt,
            priority: priority,
            repeatIntervalMinutes: repeatIntervalMinutes,
            createdAt: createdAt
        )

        if let duplicate = likelyDuplicateTask(
            title: title,
            roomLabel: roomLabel,
            createdAt: createdAt,
            dueAt: normalizedDueAt
        ) {
            duplicateTaskID = duplicate.id
            recentlyAddedTaskID = duplicate.id
            saveState()
            return duplicate
        }

        let task = ShiftTask(
            patientID: patientID,
            roomLabel: roomLabel,
            patientName: patientName,
            title: title,
            detail: detail,
            category: category,
            priority: priority,
            status: .pending,
            createdAt: createdAt,
            dueAt: normalizedDueAt,
            repeatIntervalMinutes: repeatIntervalMinutes
        )

        tasks.append(task)
        duplicateTaskID = nil
        recentlyAddedTaskID = task.id
        saveState()
        return task
    }

    func markDone(_ task: ShiftTask) {
        let completedTask = currentTask(for: task) ?? task
        let completedAt = Date()
        update(task) { item in
            item.status = .done
            item.completedAt = completedAt
            item.snoozedUntil = nil
        }
        scheduleNextOccurrenceIfNeeded(for: completedTask)
        saveState()
    }

    func snooze(_ task: ShiftTask, minutes: Int) {
        update(task) { item in
            item.status = .snoozed
            item.snoozedUntil = Date().addingTimeInterval(TimeInterval(minutes * 60))
        }
        if resurfacedTaskID == task.id {
            resurfacedTaskID = nil
        }
        saveState()
    }

    func unsnooze(_ task: ShiftTask) {
        update(task) { item in
            item.status = .pending
            item.snoozedUntil = nil
        }
        resurfacedTaskID = task.id
        saveState()
    }

    func pin(_ task: ShiftTask) {
        update(task) { item in
            item.isPinned.toggle()
        }
        saveState()
    }

    func clearRecentlyAddedTaskMarker(_ taskID: UUID?) {
        guard recentlyAddedTaskID == taskID else {
            return
        }

        recentlyAddedTaskID = nil
    }

    func clearDuplicateTaskMarker(_ taskID: UUID?) {
        guard duplicateTaskID == taskID else {
            return
        }

        duplicateTaskID = nil
    }

    func clearResurfacedTaskMarker(_ taskID: UUID?) {
        guard resurfacedTaskID == taskID else {
            return
        }

        resurfacedTaskID = nil
    }

    func refreshResurfacedTasks(now: Date = Date()) {
        guard let index = tasks.firstIndex(where: { task in
            task.status == .snoozed &&
            task.snoozedUntil.map { $0 <= now } == true
        }) else {
            return
        }

        tasks[index].status = .pending
        tasks[index].snoozedUntil = nil
        resurfacedTaskID = tasks[index].id
        saveState()
    }

    private var activeTasks: [ShiftTask] {
        activeTasks(at: Date())
    }

    private func activeTasks(at now: Date) -> [ShiftTask] {
        tasks.filter { task in
            guard task.status != .done else {
                return false
            }

            if task.status == .snoozed, let snoozedUntil = task.snoozedUntil {
                return snoozedUntil <= now
            }

            return true
        }
    }

    private func update(_ task: ShiftTask, mutate: (inout ShiftTask) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            return
        }

        mutate(&tasks[index])
    }

    private func currentTask(for task: ShiftTask) -> ShiftTask? {
        tasks.first { $0.id == task.id }
    }

    private func scheduleNextOccurrenceIfNeeded(for task: ShiftTask) {
        guard let repeatIntervalMinutes = task.repeatIntervalMinutes,
              repeatIntervalMinutes > 0 else {
            return
        }

        let now = Date()
        let baseDueAt = task.dueAt.map { max($0, now) } ?? now
        let nextDueAt = baseDueAt.addingTimeInterval(TimeInterval(repeatIntervalMinutes * 60))
        let nextTask = ShiftTask(
            patientID: task.patientID,
            roomLabel: task.roomLabel,
            patientName: task.patientName,
            title: task.title,
            detail: task.detail,
            category: task.category,
            priority: task.priority,
            status: .pending,
            createdAt: now,
            dueAt: nextDueAt,
            repeatIntervalMinutes: repeatIntervalMinutes
        )

        tasks.append(nextTask)
        recentlyAddedTaskID = nextTask.id
    }

    private func normalizedDueAt(
        _ dueAt: Date?,
        priority: TaskPriority,
        repeatIntervalMinutes: Int?,
        createdAt: Date
    ) -> Date? {
        if let dueAt {
            return dueAt
        }

        if let repeatIntervalMinutes, repeatIntervalMinutes > 0 {
            return createdAt.addingTimeInterval(TimeInterval(repeatIntervalMinutes * 60))
        }

        if priority == .routine {
            return createdAt.addingTimeInterval(60 * 60)
        }

        return nil
    }

    private func likelyDuplicateTask(
        title: String,
        roomLabel: String,
        createdAt: Date,
        dueAt: Date?
    ) -> ShiftTask? {
        guard let index = tasks.firstIndex(where: { task in
            (task.status == .pending || task.status == .snoozed) &&
            task.title == title &&
            task.roomLabel == roomLabel &&
            createdAt.timeIntervalSince(task.createdAt) <= 120
        }) else {
            return nil
        }

        if let dueAt {
            tasks[index].dueAt = dueAt
            tasks[index].snoozedUntil = nil
            tasks[index].status = .pending
        }

        return tasks[index]
    }

    private func attentionOrder(_ lhs: ShiftTask, _ rhs: ShiftTask, now: Date) -> Bool {
        let lhsRank = attentionRank(lhs, now: now)
        let rhsRank = attentionRank(rhs, now: now)

        if lhsRank != rhsRank {
            return lhsRank < rhsRank
        }

        return baselineOrder(lhs, rhs)
    }

    private func comingUpOrder(_ lhs: ShiftTask, _ rhs: ShiftTask, now: Date) -> Bool {
        let lhsRank = lhs.isPinned ? 0 : 1
        let rhsRank = rhs.isPinned ? 0 : 1

        if lhsRank != rhsRank {
            return lhsRank < rhsRank
        }

        return baselineOrder(lhs, rhs)
    }

    private func baselineOrder(_ lhs: ShiftTask, _ rhs: ShiftTask) -> Bool {
        switch (lhs.dueAt, rhs.dueAt) {
        case let (lhsDue?, rhsDue?):
            let interval = abs(lhsDue.timeIntervalSince(rhsDue))
            if interval > 60 {
                return lhsDue < rhsDue
            }

            return lhs.createdAt > rhs.createdAt
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return lhs.createdAt > rhs.createdAt
        }
    }

    private func attentionRank(_ task: ShiftTask, now: Date) -> Int {
        let isOverdue = task.dueAt.map { $0 <= now } == true

        if isOverdue && task.isPinned {
            return 0
        }

        if isOverdue {
            return 1
        }

        return task.isPinned ? 2 : 3
    }

    private func loadSavedState() -> Bool {
        do {
            let data = try Data(contentsOf: persistenceURL)
            let payload = try JSONDecoder().decode(ShiftStorePayload.self, from: data)

            patients = payload.patients
            tasks = normalizedTasks(payload.tasks)
            hasStartedShift = payload.hasStartedShift
            nurseName = payload.nurseName
            unitName = payload.unitName

            return true
        } catch {
            return false
        }
    }

    private func saveState() {
        do {
            let payload = ShiftStorePayload(
                patients: patients,
                tasks: tasks,
                hasStartedShift: hasStartedShift,
                nurseName: nurseName,
                unitName: unitName
            )
            let data = try JSONEncoder().encode(payload)
            try data.write(to: persistenceURL, options: [.atomic])
        } catch {
            assertionFailure("Unable to persist shift state: \(error)")
        }
    }

    private var persistenceURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent("miri-shift-store.json")
    }

    private func normalizedTasks(_ tasks: [ShiftTask]) -> [ShiftTask] {
        let now = Date()

        return tasks.map { task in
            var normalizedTask = task

            if normalizedTask.status == .done && normalizedTask.completedAt == nil {
                normalizedTask.completedAt = normalizedTask.createdAt
            }

            if normalizedTask.repeatIntervalMinutes != nil && normalizedTask.dueAt == nil {
                normalizedTask.dueAt = now.addingTimeInterval(TimeInterval((normalizedTask.repeatIntervalMinutes ?? 60) * 60))
            }

            if normalizedTask.priority == .routine && normalizedTask.dueAt == nil {
                normalizedTask.dueAt = now.addingTimeInterval(60 * 60)
            }

            return normalizedTask
        }
    }
}

private struct ShiftStorePayload: Codable {
    var patients: [Patient]
    var tasks: [ShiftTask]
    var hasStartedShift: Bool
    var nurseName: String
    var unitName: String

    init(
        patients: [Patient],
        tasks: [ShiftTask],
        hasStartedShift: Bool,
        nurseName: String,
        unitName: String
    ) {
        self.patients = patients
        self.tasks = tasks
        self.hasStartedShift = hasStartedShift
        self.nurseName = nurseName
        self.unitName = unitName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        patients = try container.decode([Patient].self, forKey: .patients)
        tasks = try container.decode([ShiftTask].self, forKey: .tasks)
        let storedHasStartedShift = try container.decode(Bool.self, forKey: .hasStartedShift)
        let hasSetupFields = container.contains(.nurseName) || container.contains(.unitName)
        hasStartedShift = hasSetupFields ? storedHasStartedShift : false
        nurseName = try container.decodeIfPresent(String.self, forKey: .nurseName) ?? "Mariana"
        unitName = try container.decodeIfPresent(String.self, forKey: .unitName) ?? ""
    }
}

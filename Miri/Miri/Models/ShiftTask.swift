import Foundation

enum TaskCategory: String, Codable, CaseIterable {
    case meds
    case vitals
    case followUp
    case hydration
    case paperwork
    case lab
    case note
}

enum TaskPriority: String, Codable, CaseIterable {
    case urgent
    case soon
    case followUp
    case routine
}

enum ShiftTaskStatus: String, Codable, CaseIterable {
    case pending
    case done
    case snoozed
}

struct ShiftTask: Identifiable, Codable, Hashable {
    let id: UUID
    var patientID: UUID?
    var roomLabel: String
    var patientName: String?
    var title: String
    var detail: String
    var category: TaskCategory
    var priority: TaskPriority
    var status: ShiftTaskStatus
    var createdAt: Date
    var dueAt: Date?
    var completedAt: Date?
    var snoozedUntil: Date?
    var isPinned: Bool
    var repeatIntervalMinutes: Int?

    init(
        id: UUID = UUID(),
        patientID: UUID? = nil,
        roomLabel: String,
        patientName: String? = nil,
        title: String,
        detail: String = "",
        category: TaskCategory = .followUp,
        priority: TaskPriority = .routine,
        status: ShiftTaskStatus = .pending,
        createdAt: Date = Date(),
        dueAt: Date? = nil,
        completedAt: Date? = nil,
        snoozedUntil: Date? = nil,
        isPinned: Bool = false,
        repeatIntervalMinutes: Int? = nil
    ) {
        self.id = id
        self.patientID = patientID
        self.roomLabel = roomLabel
        self.patientName = patientName
        self.title = title
        self.detail = detail
        self.category = category
        self.priority = priority
        self.status = status
        self.createdAt = createdAt
        self.dueAt = dueAt
        self.completedAt = completedAt
        self.snoozedUntil = snoozedUntil
        self.isPinned = isPinned
        self.repeatIntervalMinutes = repeatIntervalMinutes
    }

    var isOverdue: Bool {
        guard isActionableNow, let dueAt else {
            return false
        }

        return dueAt <= Date()
    }

    var isDueSoon: Bool {
        guard isActionableNow, let dueAt, !isOverdue else {
            return false
        }

        return dueAt <= Date().addingTimeInterval(30 * 60)
    }

    var isActionableNow: Bool {
        dueAt != nil && completedAt == nil && status != .done
    }
}

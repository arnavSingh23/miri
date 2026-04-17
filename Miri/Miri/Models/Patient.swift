import Foundation

enum PatientStatus: String, Codable, CaseIterable {
    case stable
    case needsAttention
    case urgent
}

struct Patient: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var room: String
    var status: PatientStatus
    var lastSeen: Date?
    var pendingTaskCount: Int

    init(
        id: UUID = UUID(),
        name: String,
        room: String,
        status: PatientStatus,
        lastSeen: Date? = nil,
        pendingTaskCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.room = room
        self.status = status
        self.lastSeen = lastSeen
        self.pendingTaskCount = pendingTaskCount
    }
}

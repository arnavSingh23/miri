import Foundation

struct MockSeed {
    static let patients: [Patient] = {
        let now = Date()

        return [
            Patient(
                name: "Avery Chen",
                room: "402",
                status: .needsAttention,
                lastSeen: now.addingTimeInterval(-25 * 60),
                pendingTaskCount: 2
            ),
            Patient(
                name: "Luis Martinez",
                room: "408",
                status: .stable,
                lastSeen: now.addingTimeInterval(-50 * 60),
                pendingTaskCount: 1
            ),
            Patient(
                name: "Mina Patel",
                room: "414",
                status: .urgent,
                lastSeen: now.addingTimeInterval(-12 * 60),
                pendingTaskCount: 1
            )
        ]
    }()

    static let tasks: [ShiftTask] = {
        let now = Date()
        let avery = patients[0]
        let luis = patients[1]
        let mina = patients[2]

        return [
            ShiftTask(
                patientID: mina.id,
                roomLabel: mina.room,
                patientName: mina.name,
                title: "Recheck pain score",
                detail: "Follow up after PRN medication.",
                category: .followUp,
                priority: .urgent,
                dueAt: now.addingTimeInterval(-5 * 60),
                isPinned: true
            ),
            ShiftTask(
                patientID: avery.id,
                roomLabel: avery.room,
                patientName: avery.name,
                title: "Repeat vitals",
                detail: "Trend after earlier elevated heart rate.",
                category: .vitals,
                priority: .soon,
                dueAt: now.addingTimeInterval(20 * 60),
                repeatIntervalMinutes: 60
            ),
            ShiftTask(
                patientID: luis.id,
                roomLabel: luis.room,
                patientName: luis.name,
                title: "Check oral intake",
                detail: "Confirm hydration before next round.",
                category: .hydration,
                priority: .followUp,
                dueAt: now.addingTimeInterval(45 * 60)
            ),
            ShiftTask(
                patientID: avery.id,
                roomLabel: avery.room,
                patientName: avery.name,
                title: "Document family update",
                detail: "Add brief note when able.",
                category: .note,
                priority: .routine,
                dueAt: now.addingTimeInterval(2 * 60 * 60)
            )
        ]
    }()
}

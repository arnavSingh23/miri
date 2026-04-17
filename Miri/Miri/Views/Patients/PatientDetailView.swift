import SwiftUI

struct PatientDetailView: View {
    @EnvironmentObject var store: ShiftStore
    let patient: Patient

    @State private var noteText = ""
    @State private var selectedTiming: PatientQuickAddTiming = .dueSoon
    @State private var showsConfirmation = false
    @State private var confirmationText = "Added"

    private let templates: [PatientQuickAddTemplate] = [
        PatientQuickAddTemplate(title: "Vitals Check", detail: "Quick vitals follow-up", category: .vitals, systemImage: "heart.text.square"),
        PatientQuickAddTemplate(title: "Meds Reminder", detail: "Medication follow-up", category: .meds, systemImage: "pills"),
        PatientQuickAddTemplate(title: "Patient Follow-Up", detail: "General follow-up needed", category: .followUp, systemImage: "person.crop.circle.badge.questionmark"),
        PatientQuickAddTemplate(title: "Fluid Intake", detail: "Monitor hydration / intake", category: .hydration, systemImage: "drop")
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                    .padding(.top, 12)

                activeTasksSection
                completedTasksSection
                quickAddSection
            }
            .padding(.horizontal, AppTheme.screenHorizontalPadding)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppTheme.background)
        .navigationTitle("Patient")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(currentPatient.name)
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Room \(currentPatient.room)")
                .font(.title3)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var activeTasksSection: some View {
        section("Active Tasks") {
            if activeTasks.isEmpty {
                emptyState("No active tasks for this patient")
            } else {
                VStack(spacing: 16) {
                    ForEach(activeTasks) { task in
                        patientTaskRow(task, showsActions: true)
                    }
                }
            }
        }
    }

    private var completedTasksSection: some View {
        section("Recently Completed") {
            if completedTasks.isEmpty {
                emptyState("Nothing completed yet")
            } else {
                VStack(spacing: 14) {
                    ForEach(completedTasks) { task in
                        patientTaskRow(task, showsActions: false)
                    }
                }
            }
        }
    }

    private var quickAddSection: some View {
        section("Quick Add") {
            VStack(alignment: .leading, spacing: 14) {
                if showsConfirmation {
                    confirmationBanner
                        .transition(.opacity)
                }

                noteField
                timingSelector

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(templates) { template in
                        Button {
                            addTemplate(template)
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                Image(systemName: template.systemImage)
                                    .font(.title3)
                                    .foregroundStyle(AppTheme.primary)

                                Text(template.title)
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
                            .padding(16)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                                    .stroke(AppTheme.outline.opacity(0.55), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var noteField: some View {
        HStack(spacing: 10) {
            TextField("Quick note...", text: $noteText)
                .font(.headline)
                .submitLabel(.done)
                .onSubmit(saveManualNote)
                .padding(.vertical, 14)
                .padding(.leading, 16)

            Button(action: saveManualNote) {
                Image(systemName: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(canSaveNote ? AppTheme.primary : AppTheme.primaryDim)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canSaveNote)
            .padding(.trailing, 8)
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.outline.opacity(0.55), lineWidth: 1)
        )
    }

    private var timingSelector: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(PatientQuickAddTiming.allCases) { option in
                Button {
                    selectedTiming = option
                } label: {
                    Text(option.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(selectedTiming == option ? .white : AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(selectedTiming == option ? option.color : AppTheme.surfaceLow)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var confirmationBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.primary)

            Text(confirmationText)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()
        }
        .padding(14)
        .background(AppTheme.primaryDim.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)

            content()
        }
    }

    private func patientTaskRow(_ task: ShiftTask, showsActions: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    if !task.detail.isEmpty {
                        Text(task.detail)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Text(roomText)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Text(taskBadgeText(for: task))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(statusColor(for: task))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(statusColor(for: task).opacity(0.14))
                    .clipShape(Capsule())
            }

            if showsActions {
                HStack(spacing: 10) {
                    Button {
                        store.markDone(task)
                    } label: {
                        Text("Mark Done")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius, style: .continuous))

                    Button {
                        store.snooze(task, minutes: 15)
                    } label: {
                        Text("Snooze 15m")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppTheme.primary)
                    .background(AppTheme.primaryDim.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius, style: .continuous))
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .shadow(color: AppTheme.textPrimary.opacity(0.035), radius: 8, x: 0, y: 4)
    }

    private func emptyState(_ message: String) -> some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(AppTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
    }

    private var currentPatient: Patient {
        store.patients.first { $0.id == patient.id } ?? patient
    }

    private var activeTasks: [ShiftTask] {
        store.tasks
            .filter { isForPatient($0) && $0.status != .done }
            .sorted(by: taskOrder)
    }

    private var completedTasks: [ShiftTask] {
        Array(
            store.tasks
                .filter { isForPatient($0) && $0.status == .done }
                .sorted { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }
                .prefix(5)
        )
    }

    private var canSaveNote: Bool {
        !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func isForPatient(_ task: ShiftTask) -> Bool {
        task.patientID == currentPatient.id || task.roomLabel == currentPatient.room
    }

    private func addTemplate(_ template: PatientQuickAddTemplate) {
        createTask(title: template.title, detail: template.detail, category: template.category)
    }

    private func saveManualNote() {
        let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedNote.isEmpty else {
            return
        }

        createTask(title: "Manual Note", detail: trimmedNote, category: .note)
        noteText = ""
    }

    private func createTask(title: String, detail: String, category: TaskCategory) {
        let task = store.addTask(
            title: title,
            detail: detail,
            category: category,
            priority: selectedTiming.priority,
            patientID: currentPatient.id,
            roomLabel: currentPatient.room,
            patientName: currentPatient.name,
            dueAt: selectedTiming.dueAt
        )

        showFeedback(for: task, title: title)
    }

    private func showFeedback(for task: ShiftTask, title: String) {
        let roomText = "Room \(task.roomLabel)"
        confirmationText = store.duplicateTaskID == task.id ? "Already added • \(title) (\(roomText))" : "Added • \(title) (\(roomText))"

        withAnimation(.easeInOut(duration: 0.2)) {
            showsConfirmation = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showsConfirmation = false
            }
            store.clearDuplicateTaskMarker(task.id)
        }
    }

    private func taskStatusText(for task: ShiftTask) -> String {
        guard let dueAt = task.dueAt else {
            return task.status == .done ? "Completed" : "Follow-Up"
        }

        let minutes = Int(dueAt.timeIntervalSince(Date()) / 60)

        if task.status == .done {
            return "Completed"
        }

        if minutes < 0 {
            return "Overdue"
        }

        if minutes == 0 {
            return "Due now"
        }

        return "In \(minutes)m"
    }

    private func taskBadgeText(for task: ShiftTask) -> String {
        taskStatusText(for: task)
    }

    private var roomText: String {
        "Room \(currentPatient.room)"
    }

    private func statusColor(for task: ShiftTask) -> Color {
        if task.status == .done {
            return AppTheme.primary
        }

        if task.isOverdue {
            return AppTheme.error
        }

        if task.isDueSoon {
            return AppTheme.tertiary
        }

        return AppTheme.secondary
    }

    private func taskOrder(_ lhs: ShiftTask, _ rhs: ShiftTask) -> Bool {
        switch (lhs.dueAt, rhs.dueAt) {
        case let (lhsDue?, rhsDue?):
            return lhsDue < rhsDue
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return lhs.createdAt > rhs.createdAt
        }
    }
}

private enum PatientQuickAddTiming: String, CaseIterable, Identifiable {
    case needsAttention
    case dueSoon
    case followUp
    case routine

    var id: String { rawValue }

    var title: String {
        switch self {
        case .needsAttention:
            return "Needs Attention"
        case .dueSoon:
            return "In 20m"
        case .followUp:
            return "Follow-Up"
        case .routine:
            return "In 1h"
        }
    }

    var priority: TaskPriority {
        switch self {
        case .needsAttention:
            return .urgent
        case .dueSoon:
            return .soon
        case .followUp:
            return .followUp
        case .routine:
            return .routine
        }
    }

    var dueAt: Date? {
        switch self {
        case .needsAttention:
            return Date().addingTimeInterval(5 * 60)
        case .dueSoon:
            return Date().addingTimeInterval(20 * 60)
        case .followUp:
            return nil
        case .routine:
            return Date().addingTimeInterval(60 * 60)
        }
    }

    var color: Color {
        switch self {
        case .needsAttention:
            return AppTheme.error
        case .dueSoon:
            return AppTheme.tertiary
        case .followUp:
            return AppTheme.secondary
        case .routine:
            return AppTheme.primary
        }
    }
}

private struct PatientQuickAddTemplate: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let category: TaskCategory
    let systemImage: String
}

#Preview {
    NavigationStack {
        PatientDetailView(patient: MockSeed.patients[0])
            .environmentObject(ShiftStore())
    }
}

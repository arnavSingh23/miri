import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var store: ShiftStore
    @State private var selectedTask: ShiftTask?
    @State private var showDemoControls = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                    .padding(.top, 24)

                snapshotSection

                if pendingTasks.isEmpty {
                    allClearSection
                }

                if !openPatientGroups.isEmpty {
                    stillOpenSection
                }

                if !snoozedTasks.isEmpty {
                    snoozedSection
                }

                if !completedTasks.isEmpty {
                    completedSection
                }

                if !ongoingTasks.isEmpty {
                    ongoingSection
                }

                demoControlsSection
            }
            .padding(.horizontal, AppTheme.screenHorizontalPadding)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppTheme.background)
        .sheet(item: $selectedTask) { task in
            TaskDetailSheet(
                task: currentTask(for: task) ?? task,
                onDone: {
                    store.markDone(task)
                    selectedTask = nil
                },
                onSnooze: {
                    store.snooze(task, minutes: 15)
                    selectedTask = nil
                },
                onPin: {
                    store.pin(task)
                    selectedTask = currentTask(for: task)
                }
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("A handoff-ready view of your current shift")
                .font(.callout)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var pendingTasks: [ShiftTask] {
        store.tasks
            .filter { $0.status != .done && $0.status != .snoozed }
            .sorted(by: summaryOrder)
    }

    private var completedTaskCount: Int {
        store.tasks.filter { $0.status == .done }.count
    }

    private var overdueCount: Int {
        pendingTasks.filter(\.isOverdue).count
    }

    private var openPatientGroups: [PatientTaskGroup] {
        let groupedTasks = Dictionary(grouping: pendingTasks) { patientKey(for: $0) }

        return groupedTasks
            .map { key, tasks in
                PatientTaskGroup(id: key, title: groupTitle(for: tasks.first), tasks: tasks.sorted(by: summaryOrder))
            }
            .sorted { $0.title < $1.title }
    }

    private var completedTasks: [ShiftTask] {
        Array(
            store.tasks
                .filter { $0.status == .done }
                .sorted { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }
                .prefix(10)
        )
    }

    private var ongoingTasks: [ShiftTask] {
        pendingTasks.filter { task in
            task.repeatIntervalMinutes != nil
        }
    }

    private var snoozedTasks: [ShiftTask] {
        store.tasks
            .filter { $0.status == .snoozed }
            .sorted { lhs, rhs in
                (lhs.snoozedUntil ?? .distantFuture) < (rhs.snoozedUntil ?? .distantFuture)
            }
    }

    private var snapshotSection: some View {
        summarySection("Shift Snapshot") {
            VStack(spacing: 12) {
                summaryCard(title: "Total Patients", value: "\(store.patients.count)", color: AppTheme.primary)
                summaryCard(title: "Open Tasks", value: "\(pendingTasks.count)", color: AppTheme.tertiary)
                summaryCard(title: "Completed Tasks", value: "\(completedTaskCount)", color: AppTheme.secondary)
                summaryCard(title: "Overdue", value: "\(overdueCount)", color: AppTheme.error)
            }
        }
    }

    private var allClearSection: some View {
        summarySection("Still Open") {
            emptyState("No open items for handoff")
        }
    }

    private var stillOpenSection: some View {
        summarySection("Still Open") {
            VStack(spacing: 12) {
                ForEach(openPatientGroups) { group in
                    patientGroupCard(group)
                }
            }
        }
    }

    private var snoozedSection: some View {
        summarySection("Still Open → Snoozed") {
            VStack(spacing: 10) {
                ForEach(snoozedTasks) { task in
                    compactTaskRow(task)
                }
            }
        }
    }

    private var completedSection: some View {
        summarySection("Recently Completed") {
            VStack(spacing: 10) {
                ForEach(completedTasks) { task in
                    completedRow(task)
                }
            }
        }
    }

    private var ongoingSection: some View {
        summarySection("Routine / Ongoing") {
            VStack(spacing: 10) {
                ForEach(ongoingTasks) { task in
                    compactTaskRow(task)
                }
            }
        }
    }

    private func summarySection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)

            content()
        }
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

    private func summaryCard(title: String, value: String, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.callout)
                    .foregroundStyle(AppTheme.textSecondary)

                Text(value)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
            }

            Spacer()
        }
        .padding(18)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .shadow(color: AppTheme.textPrimary.opacity(0.05), radius: 12, x: 0, y: 7)
    }

    private func patientGroupCard(_ group: PatientTaskGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(group.title)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            VStack(spacing: 8) {
                ForEach(group.tasks) { task in
                    compactTaskRow(task)
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .shadow(color: AppTheme.textPrimary.opacity(0.04), radius: 10, x: 0, y: 6)
    }

    private func compactTaskRow(_ task: ShiftTask) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Circle()
                .fill(priorityColor(for: task))
                .frame(width: 8, height: 8)

            Text(task.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()

            Text(timeContext(for: task))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(priorityColor(for: task))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(priorityColor(for: task).opacity(0.14))
                .clipShape(Capsule())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTask = task
        }
    }

    private func completedRow(_ task: ShiftTask) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(AppTheme.primary)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(patientContextText(for: task))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Text(completedContext(for: task))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.primary)
        }
        .padding(14)
        .background(AppTheme.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
    }

    private var demoControlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDemoControls.toggle()
                }
            } label: {
                HStack {
                    Text("Demo Controls")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.textSecondary)

                    Spacer()

                    Image(systemName: showDemoControls ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(14)
                .background(AppTheme.surfaceLow.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                        .stroke(AppTheme.outline.opacity(0.35), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if showDemoControls {
                VStack(spacing: 10) {
                    demoButton("Reset Demo Data", color: AppTheme.primary) {
                        store.resetDemoData()
                    }

                    demoButton("Seed Urgent Shift", color: AppTheme.error) {
                        store.seedUrgentDemoState()
                    }

                    demoButton("Seed Routine Shift", color: AppTheme.tertiary) {
                        store.seedRoutineDemoState()
                    }

                    demoButton("Clear All Tasks", color: AppTheme.secondary) {
                        store.clearAllTasks()
                    }

                    demoButton("End Shift", color: AppTheme.textSecondary) {
                        store.endShift()
                    }
                }
                .padding(14)
                .background(AppTheme.surfaceLow)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
                .transition(.opacity)
            }
        }
    }

    private func demoButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func timeContext(for task: ShiftTask) -> String {
        if task.status == .snoozed {
            return snoozedContext(for: task)
        }

        guard let dueAt = task.dueAt else {
            return "Hand off"
        }

        let minutes = Int(dueAt.timeIntervalSince(Date()) / 60)

        if minutes < 0 {
            return "Overdue"
        }

        if minutes == 0 {
            return "Due now"
        }

        if minutes < 60 {
            return "Due in \(minutes)m"
        }

        return "Due later"
    }

    private func snoozedContext(for task: ShiftTask) -> String {
        guard let snoozedUntil = task.snoozedUntil else {
            return "Snoozed"
        }

        let minutes = max(0, Int(snoozedUntil.timeIntervalSince(Date()) / 60))

        if minutes < 1 {
            return "Snoozed until now"
        }

        if minutes < 60 {
            return "Snoozed until \(minutes)m"
        }

        return "Snoozed until \(minutes / 60)h"
    }

    private func completedContext(for task: ShiftTask) -> String {
        let completedAt = task.completedAt ?? task.createdAt
        let minutes = max(0, Int(Date().timeIntervalSince(completedAt) / 60))

        if minutes < 1 {
            return "Completed now"
        }

        if minutes < 60 {
            return "Completed \(minutes)m ago"
        }

        return "Completed \(minutes / 60)h ago"
    }

    private func priorityColor(for task: ShiftTask) -> Color {
        if task.status == .snoozed {
            return AppTheme.secondary
        }

        if task.isOverdue {
            return AppTheme.error
        }

        if task.isDueSoon {
            return AppTheme.tertiary
        }

        if task.dueAt != nil {
            return AppTheme.primary
        }

        return AppTheme.secondary
    }

    private func priorityRank(for task: ShiftTask) -> Int {
        if task.isOverdue {
            return 0
        }

        if task.isDueSoon {
            return 1
        }

        if task.dueAt != nil {
            return 2
        }

        return 3
    }

    private func summaryOrder(_ lhs: ShiftTask, _ rhs: ShiftTask) -> Bool {
        let lhsRank = priorityRank(for: lhs)
        let rhsRank = priorityRank(for: rhs)

        if lhsRank != rhsRank {
            return lhsRank < rhsRank
        }

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

    private func patientKey(for task: ShiftTask) -> String {
        if let patientID = task.patientID {
            return patientID.uuidString
        }

        return task.roomLabel
    }

    private func groupTitle(for task: ShiftTask?) -> String {
        guard let task else {
            return "Unassigned"
        }

        return patientContextText(for: task)
    }

    private func currentTask(for task: ShiftTask) -> ShiftTask? {
        store.tasks.first { $0.id == task.id }
    }

    private func patientContextText(for task: ShiftTask) -> String {
        if task.roomLabel == "Unassigned" {
            return "Unassigned"
        }

        if let patientName = task.patientName, !patientName.isEmpty {
            return "Room \(task.roomLabel) • \(patientName)"
        }

        return "Room \(task.roomLabel)"
    }
}

private struct PatientTaskGroup: Identifiable {
    let id: String
    let title: String
    let tasks: [ShiftTask]
}

#Preview {
    SummaryView()
        .environmentObject(ShiftStore())
}

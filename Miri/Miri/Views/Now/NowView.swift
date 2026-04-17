import Foundation
import SwiftUI
import Combine

struct NowView: View {
    @EnvironmentObject var store: ShiftStore
    @State private var showsSnoozedTasks = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                    .padding(.top, 24)

                attentionSection
                dueSoonSection
                activeRoutineSection
                snoozedSection
            }
            .padding(.horizontal, AppTheme.screenHorizontalPadding)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppTheme.background)
        .onAppear {
            store.refreshResurfacedTasks()
            scheduleRecentMarkerClear(store.recentlyAddedTaskID)
            scheduleDuplicateMarkerClear(store.duplicateTaskID)
        }
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
            store.refreshResurfacedTasks()
        }
        .onChange(of: store.recentlyAddedTaskID) { _, taskID in
            scheduleRecentMarkerClear(taskID)
        }
        .onChange(of: store.resurfacedTaskID) { _, taskID in
            scheduleResurfacedMarkerClear(taskID)
        }
        .onChange(of: store.duplicateTaskID) { _, taskID in
            scheduleDuplicateMarkerClear(taskID)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Good Morning, \(displayName)")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            if let unitDisplayText {
                Text(unitDisplayText)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.primary)
            }

            Text(attentionSummary)
                .font(.callout)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var displayName: String {
        let trimmedName = store.nurseName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Mariana" : trimmedName
    }

    private var unitDisplayText: String? {
        let trimmedUnit = store.unitName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUnit.isEmpty else {
            return nil
        }

        let lowercaseUnit = trimmedUnit.lowercased()

        if lowercaseUnit.hasPrefix("unit ") || lowercaseUnit.hasPrefix("floor ") {
            return trimmedUnit
        }

        return "Unit \(trimmedUnit)"
    }

    private var attentionSummary: String {
        let count = needsAttentionTasks.count + dueSoonTasks.count + activeRoutineTasks.count
        return count == 1 ? "1 actionable item right now" : "\(count) actionable items right now"
    }

    private var actionableTasks: [ShiftTask] {
        let now = Date()

        return store.tasks.filter { task in
            guard task.status != .done,
                  task.dueAt != nil else {
                return false
            }

            if task.status == .snoozed, let snoozedUntil = task.snoozedUntil {
                return snoozedUntil <= now
            }

            return true
        }
    }

    private var needsAttentionTasks: [ShiftTask] {
        let now = Date()

        return actionableTasks
            .filter { task in
                task.dueAt.map { $0 < now } == true || task.priority == .urgent
            }
            .sorted(by: taskTimeOrder)
    }

    private var dueSoonTasks: [ShiftTask] {
        let now = Date()
        let soon = now.addingTimeInterval(30 * 60)
        let attentionIDs = Set(needsAttentionTasks.map(\.id))

        return actionableTasks
            .filter { task in
                guard !attentionIDs.contains(task.id),
                      let dueAt = task.dueAt else {
                    return false
                }

                return dueAt >= now && dueAt <= soon
            }
            .sorted(by: taskTimeOrder)
    }

    private var activeRoutineTasks: [ShiftTask] {
        let now = Date()
        let soon = now.addingTimeInterval(60 * 60)
        let hiddenIDs = Set(needsAttentionTasks.map(\.id) + dueSoonTasks.map(\.id))

        return actionableTasks
            .filter { task in
                guard !hiddenIDs.contains(task.id),
                      task.repeatIntervalMinutes != nil,
                      let dueAt = task.dueAt else {
                    return false
                }

                return dueAt >= now && dueAt <= soon
            }
            .sorted(by: taskTimeOrder)
    }

    private var snoozedTasks: [ShiftTask] {
        store.tasks
            .filter { task in
                task.status == .snoozed && task.snoozedUntil != nil
            }
            .sorted { lhs, rhs in
                (lhs.snoozedUntil ?? .distantFuture) < (rhs.snoozedUntil ?? .distantFuture)
            }
    }

    private var attentionSection: some View {
        section("Needs Attention") {
            if needsAttentionTasks.isEmpty {
                emptyState("You're all caught up")
            } else {
                taskStack(needsAttentionTasks, style: .attention)
            }
        }
    }

    private var dueSoonSection: some View {
        section("Due Soon") {
            if dueSoonTasks.isEmpty {
                emptyState("No tasks due right now")
            } else {
                taskStack(dueSoonTasks, style: .dueSoon)
            }
        }
    }

    private var activeRoutineSection: some View {
        section("Active Routine") {
            if activeRoutineTasks.isEmpty {
                emptyState("No recurring tasks due this hour")
            } else {
                taskStack(activeRoutineTasks, style: .routine)
            }
        }
    }

    private var snoozedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showsSnoozedTasks.toggle()
                }
            } label: {
                HStack {
                    Text("Snoozed (\(snoozedTasks.count))")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Image(systemName: showsSnoozedTasks ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(14)
                .background(AppTheme.surfaceLow.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)

            if showsSnoozedTasks {
                if snoozedTasks.isEmpty {
                    emptyState("No snoozed tasks")
                } else {
                    VStack(spacing: 12) {
                        ForEach(snoozedTasks) { task in
                            snoozedTaskRow(task)
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
    }

    private func taskStack(_ tasks: [ShiftTask], style: NowTaskCardStyle) -> some View {
        VStack(spacing: 16) {
            ForEach(tasks) { task in
                nowTaskCard(task, style: style)
            }
        }
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

    private func nowTaskCard(_ task: ShiftTask, style: NowTaskCardStyle) -> some View {
        HStack(spacing: 0) {
            style.accentColor
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(task.title)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)

                        VStack(alignment: .leading, spacing: 3) {
                            if let patientName = task.patientName, !patientName.isEmpty {
                                Text(patientName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppTheme.textPrimary)
                            }

                            Text(roomText(for: task))
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    Spacer()

                    Text(cardBadgeText(for: task))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(style.accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(style.accentColor.opacity(0.14))
                        .clipShape(Capsule())
                }

                HStack(spacing: 10) {
                    Button {
                        store.markDone(task)
                    } label: {
                        Text("Mark Done")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
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
                            .padding(.vertical, 11)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppTheme.primary)
                    .background(AppTheme.primaryDim.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius, style: .continuous))
                }
            }
            .padding(16)
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .shadow(color: style.accentColor.opacity(style.shadowOpacity), radius: 10, x: 0, y: 5)
    }

    private func snoozedTaskRow(_ task: ShiftTask) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                VStack(alignment: .leading, spacing: 3) {
                    if let patientName = task.patientName, !patientName.isEmpty {
                        Text(patientName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(AppTheme.textPrimary)
                    }

                    Text(roomText(for: task))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)

                    Text(snoozedUntilText(for: task))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.secondary)
                }
            }

            Spacer()

            Button {
                store.unsnooze(task)
            } label: {
                Text("Unsnooze")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primary)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(AppTheme.primaryDim.opacity(0.28))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
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

    private func timeContext(for task: ShiftTask) -> String {
        guard let dueAt = task.dueAt else {
            return "Scheduled"
        }
        let minutes = Int(dueAt.timeIntervalSince(Date()) / 60)

        if minutes < 0 {
            return "Overdue"
        }

        if minutes == 0 {
            return "Due now"
        }

        return "In \(minutes)m"
    }

    private func cardBadgeText(for task: ShiftTask) -> String {
        var parts = [timeContext(for: task)]

        if isDuplicate(task) {
            parts.append("Added")
        } else if isRecent(task) {
            parts.append("New")
        } else if isResurfaced(task) {
            parts.append("Back")
        }

        return parts.joined(separator: " • ")
    }

    private func snoozedUntilText(for task: ShiftTask) -> String {
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

    private func isRecent(_ task: ShiftTask) -> Bool {
        task.id == store.recentlyAddedTaskID
    }

    private func isDuplicate(_ task: ShiftTask) -> Bool {
        task.id == store.duplicateTaskID
    }

    private func isResurfaced(_ task: ShiftTask) -> Bool {
        task.id == store.resurfacedTaskID
    }

    private func taskTimeOrder(_ lhs: ShiftTask, _ rhs: ShiftTask) -> Bool {
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

    private func roomText(for task: ShiftTask) -> String {
        task.roomLabel == "Unassigned" ? "Unassigned" : "Room \(task.roomLabel)"
    }

    private func scheduleRecentMarkerClear(_ taskID: UUID?) {
        guard let taskID else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            store.clearRecentlyAddedTaskMarker(taskID)
        }
    }

    private func scheduleResurfacedMarkerClear(_ taskID: UUID?) {
        guard let taskID else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            store.clearResurfacedTaskMarker(taskID)
        }
    }

    private func scheduleDuplicateMarkerClear(_ taskID: UUID?) {
        guard let taskID else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            store.clearDuplicateTaskMarker(taskID)
        }
    }
}

private enum NowTaskCardStyle {
    case attention
    case dueSoon
    case routine

    var accentColor: Color {
        switch self {
        case .attention:
            return AppTheme.error
        case .dueSoon:
            return AppTheme.tertiary
        case .routine:
            return AppTheme.primary
        }
    }

    var shadowOpacity: Double {
        switch self {
        case .attention:
            return 0.14
        case .dueSoon:
            return 0.09
        case .routine:
            return 0.06
        }
    }
}
#Preview {
    NowView()
        .environmentObject(ShiftStore())
}

import Foundation
import SwiftUI

struct TaskDetailSheet: View {
    let task: ShiftTask
    let onDone: () -> Void
    let onSnooze: () -> Void
    let onPin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            contextCard
            actionRow

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppTheme.screenHorizontalPadding)
        .padding(.top, 28)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.background)
        .presentationDetents([.medium, .large])
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                priorityBadge

                if task.isPinned {
                    Label("Pinned", systemImage: "pin.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.primaryDim.opacity(0.32))
                        .clipShape(Capsule())
                }
            }

            Text(task.title)
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if !task.detail.isEmpty {
                Text(task.detail)
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var contextCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Patient Context")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textSecondary)

            detailRow(title: "Room", value: roomText)

            if let patientName = task.patientName, !patientName.isEmpty {
                detailRow(title: "Patient", value: patientName)
            }

            if let dueAt = task.dueAt {
                detailRow(title: "Timing", value: dueSummary(for: dueAt))
            }

            if let repeatLabel {
                detailRow(title: "Repeats", value: repeatLabel)
            }
        }
        .padding(18)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .shadow(color: AppTheme.textPrimary.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    private var actionRow: some View {
        VStack(spacing: 10) {
            Button(action: onDone) {
                Text("Mark Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(AppTheme.primary)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius, style: .continuous))

            HStack(spacing: 10) {
                Button(action: onSnooze) {
                    Text("Snooze 15m")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.primary)
                .background(AppTheme.primaryDim.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius, style: .continuous))

                Button(action: onPin) {
                    Text(task.isPinned ? "Unpin" : "Pin")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.textPrimary)
                .background(AppTheme.surfaceLow)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius, style: .continuous))
            }
        }
    }

    private var priorityBadge: some View {
        Text(priorityLabel)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(priorityColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(priorityColor.opacity(0.14))
            .clipShape(Capsule())
    }

    private var priorityLabel: String {
        if task.isOverdue {
            return "Needs Attention"
        }

        if task.isDueSoon {
            return "Due Soon"
        }

        if task.dueAt != nil {
            return "Scheduled"
        }

        return "Follow-Up"
    }

    private var priorityColor: Color {
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
    private var roomText: String {
        task.roomLabel == "Unassigned" ? "Unassigned" : "Room \(task.roomLabel)"
    }

    private var repeatLabel: String? {
        guard let minutes = task.repeatIntervalMinutes else {
            return nil
        }

        if minutes == 60 {
            return "Hourly"
        }

        if minutes >= 60, minutes % 60 == 0 {
            let hours = minutes / 60
            return hours == 1 ? "Hourly" : "Every \(hours)h"
        }

        return "Every \(minutes)m"
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func dueSummary(for dueAt: Date) -> String {
        let minutes = Int(dueAt.timeIntervalSince(Date()) / 60)

        if minutes < 0 {
            return "\(abs(minutes))m overdue"
        }

        if minutes == 0 {
            return "Due now"
        }

        if minutes < 60 {
            return "In \(minutes)m"
        }

        return "Later today"
    }
}

#Preview {
    TaskDetailSheet(
        task: MockSeed.tasks[0],
        onDone: {},
        onSnooze: {},
        onPin: {}
    )
}

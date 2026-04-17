import SwiftUI

struct AttentionTaskCard: View {
    let task: ShiftTask
    let onDone: () -> Void
    let onSnooze: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            AppTheme.error
                .opacity(0.72)
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    Text(urgencyLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.error)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.errorSoft)
                        .clipShape(Capsule())

                    Spacer()

                    Text(patientContextText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(task.detail)
                        .font(.callout)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 10) {
                    Button(action: onDone) {
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

                    Button(action: onSnooze) {
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
            .padding(18)
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .shadow(color: AppTheme.textPrimary.opacity(0.08), radius: 18, x: 0, y: 10)
    }

    private var urgencyLabel: String {
        guard let dueAt = task.dueAt, dueAt < Date() else {
            return "Needs Attention"
        }

        let minutes = max(1, Int(Date().timeIntervalSince(dueAt) / 60))
        return "\(minutes)m Overdue"
    }

    private var patientContextText: String {
        if task.roomLabel == "Unassigned" {
            return "Unassigned"
        }

        if let patientName = task.patientName, !patientName.isEmpty {
            return "Room \(task.roomLabel) • \(patientName)"
        }

        return "Room \(task.roomLabel)"
    }
}

#Preview {
    AttentionTaskCard(
        task: MockSeed.tasks[0],
        onDone: {},
        onSnooze: {}
    )
    .padding()
    .background(AppTheme.background)
}

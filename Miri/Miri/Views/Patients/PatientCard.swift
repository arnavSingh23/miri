import Foundation
import SwiftUI

struct PatientCard: View {
    let patient: Patient

    var body: some View {
        HStack(spacing: 0) {
            statusColor
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(patient.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.textPrimary)

                        Text("Room \(patient.room)")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Text(statusLabel)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(statusColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(statusColor.opacity(0.14))
                            .clipShape(Capsule())

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.75))
                    }
                }

                HStack(spacing: 12) {
                    Text(pendingLabel)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.textPrimary)

                    if let lastSeen = patient.lastSeen {
                        Text(lastSeenLabel(for: lastSeen))
                            .font(.callout)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .padding(18)
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .shadow(color: AppTheme.textPrimary.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    private var pendingLabel: String {
        patient.pendingTaskCount == 1 ? "1 pending item" : "\(patient.pendingTaskCount) pending items"
    }

    private var statusLabel: String {
        switch patient.status {
        case .stable:
            return "On Track"
        case .needsAttention:
            return "Needs Attention"
        case .urgent:
            return "Urgent"
        }
    }

    private var statusColor: Color {
        switch patient.status {
        case .stable:
            return AppTheme.primary
        case .needsAttention:
            return AppTheme.tertiary
        case .urgent:
            return AppTheme.error
        }
    }

    private func lastSeenLabel(for date: Date) -> String {
        let minutes = max(1, Int(Date().timeIntervalSince(date) / 60))

        if minutes < 60 {
            return "Seen \(minutes)m ago"
        }

        return "Seen \(minutes / 60)h ago"
    }
}

#Preview {
    PatientCard(patient: MockSeed.patients[0])
        .padding()
        .background(AppTheme.background)
}

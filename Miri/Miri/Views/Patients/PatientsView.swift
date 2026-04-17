import SwiftUI

struct PatientsView: View {
    @EnvironmentObject var store: ShiftStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                        .padding(.top, 24)

                    overviewCard

                    VStack(spacing: 14) {
                        ForEach(store.patients) { patient in
                            NavigationLink(value: patient) {
                                PatientCard(patient: patient)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.screenHorizontalPadding)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(AppTheme.background)
            .navigationDestination(for: Patient.self) { patient in
                PatientDetailView(patient: patient)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Patients")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Your current assignment at a glance")
                .font(.callout)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var overviewCard: some View {
        HStack(spacing: 12) {
            overviewItem(title: "Urgent", count: count(for: .urgent), color: AppTheme.error)
            overviewItem(title: "Needs Attention", count: count(for: .needsAttention), color: AppTheme.tertiary)
            overviewItem(title: "On Track", count: count(for: .stable), color: AppTheme.primary)
        }
        .padding(18)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .shadow(color: AppTheme.textPrimary.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    private func overviewItem(title: String, count: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(count)")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundStyle(color)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func count(for status: PatientStatus) -> Int {
        store.patients.filter { $0.status == status }.count
    }
}

#Preview {
    PatientsView()
        .environmentObject(ShiftStore())
}

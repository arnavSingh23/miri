import SwiftUI

struct ShiftSetupView: View {
    @EnvironmentObject var store: ShiftStore
    @State private var nurseName = "Mariana"
    @State private var unitName = ""
    @State private var rows = ShiftSetupRoomDraft.defaultRows
    @State private var didLoadInitialValues = false

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                        .padding(.top, 36)

                    setupCard {
                        labeledTextField(
                            title: "Nurse Name",
                            placeholder: "Mariana",
                            text: $nurseName
                        )
                    }

                    setupCard {
                        labeledTextField(
                            title: "Unit / Floor",
                            placeholder: "e.g. 4 West",
                            text: $unitName
                        )
                    }

                    roomSection

                    Button {
                        startShift()
                    } label: {
                        Text("Start Shift")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(canStartShift ? AppTheme.primary : AppTheme.primaryDim)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius, style: .continuous))
                    .shadow(color: AppTheme.primary.opacity(0.16), radius: 16, x: 0, y: 10)
                    .disabled(!canStartShift)
                    .padding(.top, 4)
                }
                .padding(.horizontal, AppTheme.screenHorizontalPadding)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear(perform: loadInitialValuesIfNeeded)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Set Up Your Shift")
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Add your unit and current room assignment before you begin")
                .font(.title3)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var roomSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Assigned Rooms")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)

            VStack(spacing: 12) {
                ForEach($rows) { $row in
                    roomRow($row)
                }
            }

            Button {
                rows.append(ShiftSetupRoomDraft())
            } label: {
                Label("Add Room", systemImage: "plus")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(AppTheme.primaryDim.opacity(0.24))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func roomRow(_ row: Binding<ShiftSetupRoomDraft>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Room")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.textSecondary)

                TextField("408", text: row.room)
                    .font(.headline)
                    .keyboardType(.numbersAndPunctuation)
                    .textInputAutocapitalization(.never)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Patient")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.textSecondary)

                TextField("Optional name", text: row.patient)
                    .font(.headline)
                    .textInputAutocapitalization(.words)
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.outline.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: AppTheme.textPrimary.opacity(0.04), radius: 10, x: 0, y: 6)
    }

    private func setupCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(18)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .shadow(color: AppTheme.textPrimary.opacity(0.05), radius: 12, x: 0, y: 7)
    }

    private func labeledTextField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(AppTheme.textSecondary)

            TextField(placeholder, text: text)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)
                .textInputAutocapitalization(.words)
        }
    }

    private var canStartShift: Bool {
        rows.contains { !$0.room.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func startShift() {
        let assignedRooms = rows.map { row in
            (
                room: row.room,
                patient: row.patient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : row.patient
            )
        }

        store.configureShift(
            name: nurseName,
            unit: unitName,
            rooms: assignedRooms
        )
    }

    private func loadInitialValuesIfNeeded() {
        guard !didLoadInitialValues else {
            return
        }

        nurseName = store.nurseName.isEmpty ? "Mariana" : store.nurseName
        unitName = store.unitName

        if !store.patients.isEmpty {
            rows = store.patients.map { patient in
                ShiftSetupRoomDraft(room: patient.room, patient: patient.name)
            }
        }

        didLoadInitialValues = true
    }
}

private struct ShiftSetupRoomDraft: Identifiable {
    let id: UUID
    var room: String
    var patient: String

    init(id: UUID = UUID(), room: String = "", patient: String = "") {
        self.id = id
        self.room = room
        self.patient = patient
    }

    static let defaultRows = [
        ShiftSetupRoomDraft(),
        ShiftSetupRoomDraft(),
        ShiftSetupRoomDraft()
    ]
}

#Preview {
    ShiftSetupView()
        .environmentObject(ShiftStore())
}

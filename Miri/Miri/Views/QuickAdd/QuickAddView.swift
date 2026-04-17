import Foundation
import SwiftUI
import UIKit

struct QuickAddView: View {
    @EnvironmentObject var store: ShiftStore
    @AppStorage("quickAddLastRoom") private var lastUsedRoom = ""
    @State private var noteText = ""
    @State private var selectedTiming: QuickAddTimingOption = .now
    @State private var customDueAt = Date().addingTimeInterval(45 * 60)
    @State private var showsConfirmation = false
    @State private var confirmationText = ""
    @State private var activeTemplateID: QuickAddTemplate.ID?

    private let templates: [QuickAddTemplate] = [
        QuickAddTemplate(
            title: "Vitals Check",
            detail: "Quick vitals follow-up",
            category: .vitals,
            systemImage: "heart.text.square"
        ),
        QuickAddTemplate(
            title: "Meds Reminder",
            detail: "Medication follow-up",
            category: .meds,
            systemImage: "pills"
        ),
        QuickAddTemplate(
            title: "Patient Follow-Up",
            detail: "General follow-up needed",
            category: .followUp,
            systemImage: "person.crop.circle.badge.questionmark"
        ),
        QuickAddTemplate(
            title: "Fluid Intake",
            detail: "Monitor hydration / intake",
            category: .hydration,
            systemImage: "drop"
        )
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                    .padding(.top, 24)

                patientSelector
                timingSection

                if showsConfirmation {
                    confirmationBanner
                        .transition(.opacity)
                }

                templateGrid

                quickNoteSection
                voiceSection
            }
            .padding(.horizontal, AppTheme.screenHorizontalPadding)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppTheme.background)
        .onAppear {
            if !patientRooms.contains(lastUsedRoom) {
                lastUsedRoom = store.patients.first?.room ?? ""
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Add")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("What would you like to record?")
                .font(.callout)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var quickNoteField: some View {
        HStack(spacing: 10) {
            TextField("Quick note...", text: $noteText)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
                .submitLabel(.done)
                .onSubmit {
                    saveManualNote()
                }
                .padding(.vertical, 14)
                .padding(.leading, 16)

            Button {
                saveManualNote()
            } label: {
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
        .shadow(color: AppTheme.textPrimary.opacity(0.05), radius: 12, x: 0, y: 7)
    }

    private var voiceButton: some View {
        Button {} label: {
            VStack(spacing: 10) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 32, weight: .semibold))

                Text("Voice Note")
                    .font(.headline)
            }
            .foregroundStyle(AppTheme.primary)
            .frame(width: 156, height: 156)
            .background(AppTheme.surfaceHigh)
            .clipShape(Circle())
            .shadow(color: AppTheme.primary.opacity(0.14), radius: 18, x: 0, y: 10)
            .overlay(
                Circle()
                    .stroke(AppTheme.primaryDim.opacity(0.65), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.primaryDim.opacity(0.7), lineWidth: 1)
        )
    }

    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("When")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Text(selectedTiming.subtitle(for: customDueAt))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primary)
            }

            VStack(alignment: .leading, spacing: 14) {
                timingSelector

                if selectedTiming == .custom {
                    DatePicker("Custom Time", selection: $customDueAt, displayedComponents: [.hourAndMinute])
                        .font(.callout)
                        .foregroundStyle(AppTheme.textPrimary)
                        .tint(AppTheme.primary)
                }
            }
            .padding(16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .stroke(AppTheme.primaryDim.opacity(0.75), lineWidth: 1)
            )
            .shadow(color: AppTheme.primary.opacity(0.10), radius: 14, x: 0, y: 8)
        }
    }

    private var patientSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Patient")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(store.patients) { patient in
                        patientChip(patient)
                    }
                }
                .padding(.vertical, 2)
            }

            if store.patients.isEmpty {
                emptyState("Set up assigned patients before adding tasks")
            }
        }
    }

    private func patientChip(_ patient: Patient) -> some View {
        let isSelected = selectedPatient?.id == patient.id

        return Button {
            lastUsedRoom = patient.room
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text("Room \(patient.room)")
                    .font(.caption)
                    .fontWeight(.semibold)

                if patient.name != "Name pending", patient.name != "Patient TBD" {
                    Text(patient.name)
                        .font(.caption2)
                        .lineLimit(1)
                }
            }
            .foregroundStyle(isSelected ? .white : AppTheme.textPrimary)
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(isSelected ? AppTheme.primary : AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius, style: .continuous)
                    .stroke(isSelected ? AppTheme.primary : AppTheme.outline.opacity(0.45), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var timingSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(QuickAddTimingOption.allCases) { option in
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
    }

    private var templateGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("What")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Text("Tap to add")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(templates) { template in
                    Button {
                        addTemplateTask(template)
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
                        .shadow(color: AppTheme.textPrimary.opacity(0.06), radius: 12, x: 0, y: 7)
                        .scaleEffect(activeTemplateID == template.id ? 0.96 : 1)
                        .animation(.spring(response: 0.18, dampingFraction: 0.75), value: activeTemplateID)
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedPatient == nil)
                }
            }
        }
    }

    private var quickNoteSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick Note")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textPrimary)

            quickNoteField
        }
    }

    private var voiceSection: some View {
        VStack(spacing: 10) {
            voiceButton

            Text("Voice capture later")
                .font(.callout)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
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

    private var canSaveNote: Bool {
        selectedPatient != nil && !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var patientRooms: [String] {
        store.patients.map(\.room)
    }

    private var selectedRoomLabel: String {
        if patientRooms.contains(lastUsedRoom) {
            return lastUsedRoom
        }

        return store.patients.first?.room ?? ""
    }

    private var selectedPatientName: String? {
        guard let name = selectedPatient?.name,
              name != "Name pending",
              name != "Patient TBD" else {
            return nil
        }

        return name
    }

    private func addTemplateTask(_ template: QuickAddTemplate) {
        triggerFeedback(for: template.id)
        createTask(
            title: template.title,
            detail: template.detail,
            category: template.category
        )
    }

    private func createTask(title: String, detail: String, category: TaskCategory) {
        guard let selectedPatient else {
            return
        }

        let task = store.addTask(
            title: title,
            detail: detail,
            category: category,
            priority: selectedTiming.priority,
            patientID: selectedPatient.id,
            roomLabel: selectedPatient.room,
            patientName: selectedPatientName,
            dueAt: selectedDueAt
        )
        lastUsedRoom = selectedPatient.room
        showCaptureFeedback(for: task, title: title)
    }

    private func saveManualNote() {
        let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedNote.isEmpty else {
            return
        }

        triggerFeedback()
        createTask(
            title: "Manual Note",
            detail: trimmedNote,
            category: .note
        )

        noteText = ""
    }

    private func showCaptureFeedback(for task: ShiftTask, title: String) {
        if store.duplicateTaskID == task.id {
            confirmationText = "Already added • \(title) (\(roomFeedbackText(for: task)))"
        } else {
            confirmationText = "Added • \(title) (\(roomFeedbackText(for: task)))"
        }

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

    private func triggerFeedback(for templateID: QuickAddTemplate.ID? = nil) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        guard let templateID else {
            return
        }

        activeTemplateID = templateID

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            activeTemplateID = nil
        }
    }

    private var selectedPatient: Patient? {
        store.patients.first { $0.room == selectedRoomLabel }
    }

    private var selectedDueAt: Date? {
        selectedTiming.dueAt(customDueAt: customDueAt)
    }

    private func roomFeedbackText(for task: ShiftTask) -> String {
        "Room \(task.roomLabel)"
    }
}

private enum QuickAddTimingOption: String, CaseIterable, Identifiable {
    case now
    case in15
    case in30
    case in1h
    case custom

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .now:
            return "Now"
        case .in15:
            return "In 15m"
        case .in30:
            return "In 30m"
        case .in1h:
            return "In 1h"
        case .custom:
            return "Custom"
        }
    }

    var priority: TaskPriority {
        switch self {
        case .now:
            return .urgent
        case .in15, .in30:
            return .soon
        case .in1h, .custom:
            return .routine
        }
    }

    func dueAt(customDueAt: Date) -> Date? {
        switch self {
        case .now:
            return Date()
        case .in15:
            return Date().addingTimeInterval(15 * 60)
        case .in30:
            return Date().addingTimeInterval(30 * 60)
        case .in1h:
            return Date().addingTimeInterval(60 * 60)
        case .custom:
            return customDueAt
        }
    }

    var color: Color {
        switch self {
        case .now:
            return AppTheme.error
        case .in15, .in30:
            return AppTheme.tertiary
        case .in1h, .custom:
            return AppTheme.primary
        }
    }

    func subtitle(for customDueAt: Date) -> String {
        switch self {
        case .now:
            return "Actionable immediately"
        case .in15:
            return "Due in 15 minutes"
        case .in30:
            return "Due in 30 minutes"
        case .in1h:
            return "Due in 1 hour"
        case .custom:
            return customDueAt.formatted(date: .omitted, time: .shortened)
        }
    }
}

private struct QuickAddTemplate: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let category: TaskCategory
    let systemImage: String
}

#Preview {
    QuickAddView()
        .environmentObject(ShiftStore())
}

# Miri

Miri is a calm, native iPhone and Apple Watch shift assistant for nurses. It is a cognitive safety net for a busy shift: it helps track follow-ups, surface what needs attention, and remember what may be slipping. Miri is not an EHR, charting replacement, clinical decision-maker, or hospital integration layer.

## MVP Scope

The first MVP is local-first and mock-data only. It should compile cleanly, feel calm and low-friction, and prioritize deterministic task grouping before any AI features.

Planned iPhone screens:
- Start Shift
- Now
- Patients
- Quick Add
- Summary
- Task detail/action sheet

Planned Watch companion, later:
- Glance
- Quick add
- Quick action

Initial functionality:
- Show mock patients and tasks
- Group tasks into Needs Attention, Coming Up Soon, and Unresolved Follow-Ups
- Mark tasks done, snooze tasks, and pin tasks
- Show patient context such as room, last seen, and pending count

Out of scope for now: backend, auth, networking, persistence, notifications, hospital integrations, EHR/charting behavior, clinical recommendations, and LLM integration.

## Project Structure

Current app layout:
- `Miri/Miri.xcodeproj` - Xcode project
- `Miri/Miri/` - iPhone app target
- `Miri/Miri-Watch Watch App/` - Watch app target, reserved until explicitly worked on

Planned iPhone app organization:
- `Models/` - lightweight mock-domain types for patients, tasks, and shift state
- `Data/` - mock data and deterministic grouping helpers
- `Views/` - screen-level SwiftUI views
- `Components/` - small reusable SwiftUI components
- `Design/` - local color, spacing, typography, and card styling helpers

Keep the code simple, native SwiftUI-first, and easy to iterate on.

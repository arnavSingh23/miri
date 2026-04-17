# Miri Agent Guide

## Product Intent

Miri is a calm iPhone-first shift assistant for nurses. Treat it as a cognitive safety net, not a to-do app. It supports clinical judgment by helping nurses remember follow-ups and shifting priorities, but it must never make clinical decisions or present itself as a charting, EHR, or medical advice tool.

The UI direction is soft, modern, time-aware, and low-friction. Preserve the gentle non-clinical tone and concepts from the Stitch designs: Needs Attention, Coming Up Soon, Unresolved Follow-Ups, patient context, rounded cards, soft color, and voice-first quick add.

## Architecture Boundaries

- Build the MVP local-first with mock data only.
- Prefer deterministic grouping and state logic over clever abstractions.
- Keep models small and plain.
- Keep SwiftUI views readable and split only when complexity justifies it.
- Favor native Apple platform patterns over custom frameworks.
- Keep iPhone app code under `Miri/Miri/`.
- Do not modify the Watch app target under `Miri/Miri-Watch Watch App/` until explicitly asked.

## Do Not Build Yet

- Backend services
- Authentication or accounts
- Networking
- Persistence or databases
- Push/local notifications
- EHR, charting, or hospital integrations
- Clinical recommendations or diagnosis support
- LLM or AI integration
- Production voice transcription
- Watch app features unless explicitly requested

## Coding Style

- Make small, compile-safe changes.
- Use clear Swift names that reflect product language.
- Keep state local and obvious for the MVP.
- Prefer simple structs, enums, and SwiftUI views.
- Avoid broad refactors, global architecture rewrites, and speculative layers.
- Add comments only when they clarify non-obvious product or scheduling logic.
- Maintain a calm visual system: soft colors, rounded cards, clear hierarchy, and accessible contrast.

## Workflow Rules

- Make small scoped changes only.
- Do not perform sweeping rewrites.
- Do not modify existing Swift files unless the task explicitly asks for implementation work.
- Before changing behavior, understand the current app structure.
- Keep changes aligned with the MVP and leave future integrations as documented boundaries.

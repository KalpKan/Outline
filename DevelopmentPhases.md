# Development Phases: Circle Variability Analyzer

## Phase 1: MVP (Minimum Viable Product)
- Full-screen PencilKit canvas (Apple Pencil + finger input)
- Fixed, non-intrusive template circle overlay (250pt radius)
- Trial-based sessions: Save multiple drawings as "trials" in a session
- Export all trial data (x, y, timeOffset for every point) as pretty-printed JSON
- Share sheet integration for exporting JSON

## Phase 2: P1 Enhancements
- Real-time Mean Radial Error (MRE) calculation and display for each trial
- Prompt for self-reported fatigue score (1-10) at session start; embed in export
- Improved session management (view, delete, or re-name trials)

## Phase 3: UI/UX Polish & Accessibility
- Refine UI for Apple Human Interface Guidelines (HIG) compliance
- Add onboarding/help screens
- Accessibility improvements (VoiceOver, Dynamic Type)
- App icon and launch screen

## Phase 4: Advanced Features (Future)
- Support for additional shapes/templates
- Data import (re-load previous sessions)
- Cloud sync or backup
- Export as image or PDF

---
Each phase builds on the previous, ensuring a stable and user-friendly app at every stage. 
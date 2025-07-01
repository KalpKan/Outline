# Development Phases: Circle Variability Analyzer

> **Note:** All exported data formats (e.g., JSON) should be structured so that the output is easily interpretable and importable in OpenCV (Python) for downstream analysis.
> 
> **iPad Compatibility:** All features and UI must be tested and fully compatible on iPad devices. In Xcode, ensure:
> - The deployment target is set to iOS 13.0 or later (iOS 17+ recommended).
> - The app's supported device family includes iPad (check in the project target's General tab).
> - The main interface and all layouts are designed for iPad screen sizes and orientations.
> - PencilKit is imported and linked in the project.

## Data Format & Analysis Pipeline

### Raw Data Capture per Trial
```json
[
  { "x": 104.2, "y": 318.6, "t": 0.00 },
  { "x": 105.8, "y": 315.1, "t": 0.02 },
  ...
]
```
- **x, y**: Pixel coordinates from PencilKit strokes
- **t**: Timestamp in seconds from stroke start
- One JSON file per drawn circle
- Exclude first 5 practice trials from export

### MSE Calculation Pipeline (Python/NumPy)
1. **Load points**: `pts = np.array([[x1,y1], [x2,y2], ...])`
2. **Remove translation**: Center at (0,0) using centroid
3. **Normalize radius**: Scale to target radius (250px)
4. **Resample to uniform angles**: 360 points at 1° intervals
5. **Compute squared error**: `err(θ) = (r(θ) - R)²`
6. **Calculate MSE**: `MSE = (1/N) ∑(r_i - R)²`

### Trial Metadata to Log
| Field | Example | Notes |
|-------|---------|-------|
| trial_id | "2025-06-30T18:05:23Z" | ISO timestamp |
| fatigue_rating | 7 | Self-reported (1-10) |
| mse | 112.4 | Shape-only MSE |
| raw_points_file | "circle-20250630-1805.json" | Link to stroke data |

## Phase 1: MVP (Minimum Viable Product)
- Full-screen PencilKit canvas (Apple Pencil + finger input)
- Fixed, non-intrusive template circle overlay (250pt radius)
- Trial-based sessions: Save multiple drawings as "trials" in a session
- **Export trial data in specified JSON format**: `[{x, y, t}]` per trial
- **Exclude first 5 practice trials** from data export
- Share sheet integration for exporting JSON
- **Animated guide circle** for first 5 practice trials

## Phase 2: P1 Enhancements
- **Real-time MSE calculation** using the specified pipeline ✅
- **Display MSE score** for each trial immediately after drawing ✅
- Prompt for self-reported fatigue score (1-10) at session start; embed in export ✅
- Improved session management (view, delete, or re-name trials) ⬜️ (in progress)
- **Export both raw stroke data AND computed MSE values** ✅

## Phase 3: UI/UX Polish & Accessibility
- Refine UI for Apple Human Interface Guidelines (HIG) compliance
- Add onboarding/help screens
- Accessibility improvements (VoiceOver, Dynamic Type)
- App icon and launch screen
- **Real-time feedback on drawing quality** (MSE visualization)

## Phase 4: Advanced Features (Future)
- Support for additional shapes/templates
- Data import (re-load previous sessions)
- Cloud sync or backup
- Export as image or PDF
- **Advanced analytics dashboard** with MSE trends
- **Statistical analysis tools** for research use

---
Each phase builds on the previous, ensuring a stable and user-friendly app at every stage. 
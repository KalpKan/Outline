# Methods: Circle Variability Analyzer

## Experiment Design

The Circle Variability Analyzer is an iPad-based experiment designed to assess motor control and drawing consistency. Participants are instructed to draw circles as accurately as possible, using either an Apple Pencil or their finger, on a digital canvas. The experiment consists of two phases:

1. **Practice Phase**: The first 5 trials are warm-up/practice attempts. During these, a blue animated guide circle is displayed to help participants understand the ideal circle size and shape. Data from these trials are not included in the final analysis.
2. **Test Phase**: All subsequent trials are recorded for analysis. The guide circle is removed, and participants attempt to replicate the ideal circle from memory.

At the start of each session, participants are prompted to self-report their fatigue level on a scale from 1 (not tired) to 10 (extremely tired). This value is recorded as session metadata.

## Data Collection

For each test trial (after the first 5 practice trials), the following data are recorded:

- **Raw Stroke Points**: Each drawing is captured as a sequence of points, each with:
  - `x`: X coordinate (pixels)
  - `y`: Y coordinate (pixels)
  - `t`: Time offset (seconds) from the start of the stroke
- **Trial Metadata**:
  - `trial_id`: ISO 8601 timestamp of trial start
  - `fatigue_rating`: Self-reported fatigue score (if available)
  - `mse`: Mean Squared Error (see below)
  - `raw_points_file`: Filename of the JSON file containing the raw stroke points
- **Session Metadata**:
  - `session_id`: Unique identifier for the session
  - `created`: Timestamp of session start
  - `fatigue_rating`: Self-reported fatigue score
  - `trials`: Array of trial metadata (see above)

All data are exported in JSON format, with one file per trial (raw points) and a session metadata file summarizing all trials.

## Mathematical Analysis

### Preprocessing
1. **Translation Removal**: The centroid (mean x, y) of all points in a trial is computed and subtracted from each point, centering the drawing at (0, 0).
2. **Radius Normalization**: The mean radius (distance from the origin) of all points is computed. All points are then scaled so that the mean radius matches the target value (250 pixels).

### Resampling to Uniform Angles
- The drawing is resampled to 360 points, one for each degree (0° to 359°). For each angle θ, the point in the stroke with the closest angle (arctangent of y/x) is selected, and its radius is recorded as r(θ).

### Mean Squared Error (MSE) Calculation
- For each resampled angle θ, the squared error is computed as:
  - `err(θ) = (r(θ) - R)^2`, where R is the target radius (250 px)
- The MSE is then:
  - `MSE = (1/N) ∑_{i=1}^N (r_i - R)^2`, where N = 360

### Pseudocode (Python/NumPy style)
```python
pts = np.array([[x1, y1], [x2, y2], ...])
pts -= pts.mean(axis=0)  # Center
scale = target_R / np.linalg.norm(pts, axis=1).mean()
pts *= scale             # Normalize radius
angles = np.deg2rad(np.arange(360))
radii = np.linalg.norm(pts, axis=1)
thetas = np.arctan2(pts[:,1], pts[:,0])
r_theta = np.empty(360)
for i, ang in enumerate(angles):
    idx = np.argmin(np.abs(np.unwrap(thetas - ang)))
    r_theta[i] = radii[idx]
mse = ((r_theta - target_R) ** 2).mean()
```

### Value Summary
- **x, y, t**: Raw stroke coordinates and time offset for each point
- **trial_id**: Unique timestamp for each trial
- **fatigue_rating**: Self-reported, per session and per trial (if available)
- **mse**: Shape-only mean squared error for each trial
- **raw_points_file**: Link to the JSON file with raw points
- **session_id, created**: Session-level metadata

## Export Format
- Each test trial: `circle-YYYYMMDD-HHMM.json` (raw points)
- Session summary: `session-metadata.json` (metadata and MSEs)

## Notes
- Practice trials (first 5) are excluded from analysis and export.
- All calculations are performed in Swift using the same logic as the pseudocode above, ensuring compatibility with Python/OpenCV analysis pipelines. 
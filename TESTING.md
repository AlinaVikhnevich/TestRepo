# Testing Instructions

This document defines how Codex must validate changes **without executing R code**.
The goal is to reproduce **Our World in Data–style time-lapse behavior** while preserving the existing RMarkdown design.

---

## 1. Environment Limitation

- The execution environment used by Codex does **not** include `Rscript`.
- Codex must **not** attempt to render any R Markdown files.
- All validation must be performed via **static code inspection**.

---

## 2. Core Interaction Model (Authoritative)

This project explicitly follows the **Our World in Data (OWID)** time-lapse model.

### Key Rule
**Do NOT rely on Plotly’s native animation frames as the primary time controller.**

Instead, playback must be driven by:
- a shared time state
- explicit Play / Pause logic
- slider synchronization
- manual updates via `Plotly.react()` or `Plotly.restyle()`

---

## 3. Static Checks Codex Must Perform

Codex must verify **all** of the following by inspecting the code.

### 3.1 Time State Management

For each visualization (map, income bars, continent lines):

- A single shared variable exists representing current time (e.g. `currentYear`, `yearIndex`)
- This variable is used by:
  - Play button logic
  - Pause button logic
  - Slider input handler
- No duplicate or independent time states exist for the same visual

---

### 3.2 Play Button Logic

Codex must confirm that the Play button:

- Starts playback **only if no timer is already running**
- Resets playback to the **earliest year**
- Advances time forward in fixed increments
- Triggers a render/update on every tick
- Does **not** recreate the plot object

---

### 3.3 Pause Button Logic

Codex must confirm that the Pause button:

- Stops the active playback timer
- Preserves the current year
- Does not reset the slider or visualization

---

### 3.4 Slider Behavior

Codex must confirm that the slider:

- Updates the shared time state
- Immediately updates the visualization
- Does **not** automatically start playback
- Remains visible at all times

---

### 3.5 Single Active Timer Rule

Codex must confirm that:

- Multiple Play clicks cannot create multiple timers
- Guard logic exists to prevent overlapping intervals

---

## 4. Rendering Method Validation

Codex must confirm that updates occur via:

- `Plotly.react()` **or**
- `Plotly.restyle()`

Codex must confirm that the following **do not occur**:

- Rebuilding the entire plot during playback
- Reassigning geometry or axes
- Year-based filtering that removes entities

---

## 5. Choropleth Map Stability Rules (Critical)

For the world map:

- The base trace defines a **constant set of ISO-3 locations**
- `locations.length` remains identical across all years
- Geometry is created once and never replaced
- Time updates change **only**:
  - `z`
  - `text`
  - `customdata`
- Missing values are represented as `NA` / `null`
- Countries must **never disappear or reappear** during playback

---

## 6. Speed Requirements

Codex must verify that:

- Each visualization has its **own playback speed**
- Map playback is approximately **4× faster** than the baseline feel
  - Target range: **125–160 ms per year**
- Bars and lines may be slower but must use explicit constants

---

## 7. Forbidden Patterns

Codex must ensure **none** of the following are used:

- Plotly animation frames as the primary controller
- `htmlwidgets::onRender()` timers
- Custom JavaScript timers that are disconnected from shared time state
- Per-year `filter()` calls that drop entities

---

## 8. What the User Validates Locally

The user will validate locally by running:

```r
rmarkdown::render("test_best_visual.Rmd")

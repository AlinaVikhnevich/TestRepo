# TESTING.md

## Scope and rules (read first)

Goal: Fix missing polygons for **Kosovo**, **Cyprus (parts)**, and **Somalia (parts)** in the Plotly choropleth map.

Hard rules:
- **Do not modify `best_visual.Rmd`** (reference only).
- Make changes **only** in `test_best_visual.Rmd` (and optional helper scripts).
- **No layout, styling, font, theme, sizing, button placement, or UI changes.**
- Do not “simplify” the visualization. The rendered HTML must look the same as the expected visual, except the missing regions must appear correctly.

Do not commit large rendered artifacts:
- Do **not** add rendered HTML outputs to the repo if they are huge.
- Codex should render locally inside the devcontainer and inspect results.

Codex must create/update a log file:
- Create or update `report.txt` every time work is performed.
- `report.txt` must explain what was changed, why, what commands were run, and what the results were.
- If anything is ambiguous, list questions in `report.txt` (but do not expand scope).

---

## Environment snapshot

This repository includes:
- `sessionInfo.txt` (R session snapshot). Use it to match package versions when diagnosing environment-dependent behavior.

Optional: If `renv.lock` is ever added, prefer `renv::restore()` for reproducibility.

---

## How to run Codex (required)

Run Codex from repo root with write permissions enabled:

```bash
codex -a never -C /workspaces/TestRepo -c 'sandbox_mode="workspace-write"' exec "<commands>"

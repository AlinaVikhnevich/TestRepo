# Testing Instructions

## Environment Limitation
- The execution environment used by Codex does not include `Rscript`.
- Codex must **not** attempt to render any R Markdown files.

## Static Checks Codex Must Perform
- Confirm Plotly animations are defined with `frames`.
- Verify slider steps call `method = "animate"`.
- Ensure Play/Pause controls are provided via `updatemenus` buttons.
- Confirm there are no custom JavaScript timers or `htmlwidgets::onRender` animation logic.
- Check the choropleth map keeps a constant set of `locations` in the base trace.
- Ensure frames only update data fields (`z`, `customdata`) for the map.

## What the User Validates Locally
- Render with `rmarkdown::render("test_best_visual.Rmd")`.
- Sliders are visible for every visual.
- Play/Pause buttons are visible and functional for every visual.
- Choropleth map shows no flicker or disappearing countries.
- Map animation plays approximately 4× faster than the original baseline.

## Passing Criteria for Codex
- If the above static checks succeed, Codex should treat the test step as **pass** without attempting to run R.

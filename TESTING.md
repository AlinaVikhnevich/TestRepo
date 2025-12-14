# TESTING.md

## Scope and rules (read first)

**Goal:** Fix missing polygons for **Kosovo**, **Cyprus (parts)**, and **Somalia (parts)** in the Plotly choropleth map output.

### Hard rules
- **Do not modify** `best_visual.Rmd` (reference only).
- Make changes **only** in `test_best_visual.Rmd` (and optional helper scripts if needed).
- **No layout/styling changes**: do not change fonts, theme, sizing, margins, background image, button placement, titles, labels, or CSS.
- Do not “simplify” the visualization. The rendered HTML must look identical to the expected visual **except** the missing regions must appear correctly.

### Do not commit large artifacts
- Do **not** add large rendered HTML files to the repo.
- Render locally inside the devcontainer and inspect results there.

### Required logging
- Codex must **create or update** `report.txt` every time work is performed.
- `report.txt` must include: what changed, why, commands run, and results.
- If anything is ambiguous, list questions in `report.txt` (without expanding scope).

---
  
  ## Environment snapshot
  
  This repository includes:
  - `sessionInfo.txt` (R session snapshot). Use it to match versions when diagnosing environment-dependent behavior.

Optional:
  - If `renv.lock` is ever added, prefer using `renv::restore()` for reproducibility.

---
  
  ## How to run Codex (required)
  
  - Run Codex from the repo root with write permissions enabled:
  
```bash
codex -a never -C /workspaces/TestRepo -c 'sandbox_mode="workspace-write"' exec "<commands>"
```
---
  
  ## Quick sanity checks (before rendering)

  - From repo root:
  
```bash
cd /workspaces/TestRepo
ls -la
```
  Confirm key files exist:
  
- test_best_visual.Rmd
- best_visual.Rmd
- life-expectancy.csv
- OldMap.jpg (optional, code may use URL)
- broken output/ and expected visual/
--- 

  ##  Render and inspect (primary test)

  Render to HTML (local only)
  Use R (preferred):
  
```bash
cd /workspaces/TestRepo
R -q -e 'rmarkdown::render("test_best_visual.Rmd", output_file="test_best_visual_from_codex.html")'
ls -lh test_best_visual_from_codex.html
```

  If Rscript exists, this is also acceptable:
  
```bash
cd /workspaces/TestRepo
Rscript -e 'rmarkdown::render("test_best_visual.Rmd", output_file="test_best_visual_from_codex.html")'
ls -lh test_best_visual_from_codex.html
```

  If Rscript is missing, do not treat it as a failure. Use R -q -e ... instead.
  
  Open the output (inside Codespaces/devcontainer)
  Any one of these is fine:
  
```bash
python3 -m http.server 8000
```
  Then open:
  
 - http://localhost:8000/test_best_visual_from_codex.html

  Or use your editor’s “Open in Browser” feature.
--- 

  ## What “pass” looks like
  The fix is accepted only if all are true:
  
 - Kosovo appears on the map in the correct location and behaves like other countries (hover, coloring).
 - Cyprus shows as a whole territory (no missing parts).
 - Somalia shows as a whole territory (no missing parts).
 - The map does not lose the intended global framing/extent relative to the expected visual.
 - No other visual changes: styling, spacing, labels, background, and UI controls remain the same.
--- 
  ## Debug checklist Codex should run (if still broken)
  Confirm GeoJSON contains target features
  Inside R (Codex can run this in the devcontainer):
  
```{r}
geo_iso <- vapply(world_geojson$features, function(f) f$properties$iso_a3, character(1))
cat("Has XKX:", "XKX" %in% geo_iso, "\n")
cat("Has CYP:", "CYP" %in% geo_iso, "\n")
cat("Has SOM:", "SOM" %in% geo_iso, "\n")
```

  Confirm year payload includes proper ISO-3 codes
  For a known year (e.g., 2023):
  
```r
tmp <- get_year_data(2023)
cat("Rows:", nrow(tmp), "\n")
print(head(tmp[, c("Code","Entity","life_expectancy","Year")], 20))
```

Verify Kosovo is not stuck as Code == -99 in the final data feeding Plotly. If the plotted locations field is not ISO-3 for these entities, Plotly will not match polygons correctly.

  ### Inspect what is being passed to plot_ly()
  Codex should print the unique values and counts for:
  
  - locations column used by Plotly
  - any join key used to merge with GeoJSON

Example:
  
```{r}
cat("Unique location codes (sample):\n")
print(head(sort(unique(tmp$Code)), 50))
```
--- 

  ## Mandatory output after each attempt
  Codex must update report.txt with:
  
  - Attempt number
  - Files changed
  - Exact commands run
  - What was observed in the rendered map
  - Whether Kosovo/Cyprus/Somalia are fixed
  - Next steps (if not fixed)

No other work should be performed outside this scope.

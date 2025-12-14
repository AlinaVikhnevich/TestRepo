# TESTING.md

## Scope and rules (read first)

**Goal:** Fix missing polygons for **Kosovo**, **Somalia (parts)**, and **Cyprus (parts)** in the Plotly choropleth map.

**Hard rules**
- Do not modify `best_visual.Rmd` (reference only).
- Make changes only in `test_best_visual.Rmd` (and, if needed, small helper files).
- Do not change layout, styling, fonts, theme, sizing, button placement, or UI behavior.
- Do not change the dataset or the meaning of the visualization.
- Do not commit large rendered artifacts (big `.html`).

**Artifacts provided for visual comparison**
- Broken screenshot/PDF: `broken output/`
- Expected screenshot/PDF: `expected visual/`

## Repository structure

Key files:
- `best_visual.Rmd`  
  Reference, known-good baseline. **Must not be changed.**
- `test_best_visual.Rmd`  
  Working file. **All fixes must be applied here.**
- `life-expectancy-filtered.csv`, `life-expectancy.csv` and metadata JSON files  
  Data sources.
- `OldMap.jpg`  
  Background image.
- `sessionInfo.txt`  
  Environment snapshot.

## What is currently broken

The rendered map is missing:
- Kosovo (should appear as its own region)
- Parts of Somalia
- Parts of Cyprus

The design and layout of the rendered HTML are correct. Only the missing polygons must be fixed.

## Known context from debugging

- GeoJSON feature count reported: 241
- GeoJSON contains `XKX` (Kosovo), `CYP` (Cyprus), `SOM` (Somalia)
- Data payload for year 2023 produced 241 rows with 12 NAs in `life_expectancy`
- Data rows show some entities with `Code == -99` (examples observed: Kosovo, Indian Ocean Territory, Ashmore and Cartier Islands, Siachen Glacier)
- `world` (sf) includes Kosovo with `iso_a3 == "XKX"` and `name == "Kosovo"`

The issue is likely a mismatch between:
- the column used as Plotly `locations` in `choropleth` (for example `Code`)
and
- the GeoJSON feature id key (for example `properties.iso_a3`)

If `locations` uses `Code` but Kosovo is `-99`, Plotly cannot match it to `XKX`.

## How Codex must work

Codex must create or update a log file:
- Create or update `report.txt` every time work is performed.
- `report.txt` must include:
  - what was changed
  - why it was changed
  - commands that were run
  - what was verified
  - remaining questions (if any), without expanding scope

## How to run commands (devcontainer)

Run from repo root.

### Quick environment check

```bash
cd /workspaces/TestRepo
R -q -e 'sessionInfo()'
```

### Package versions

```bash
cd /workspaces/TestRepo
R -q -e 'pkgs <- c("plotly","sf","s2","dplyr","tidyr","jsonlite","rmarkdown"); for (p in pkgs) { cat(p, ": ", if (requireNamespace(p, quietly=TRUE)) as.character(packageVersion(p)) else "NOT INSTALLED", "\n", sep="") }'
```

### Render the R Markdown (local only)

Do not commit the output HTML if it is large.

```bash
cd /workspaces/TestRepo
R -q -e 'rmarkdown::render("test_best_visual.Rmd", output_file = "test_best_visual_rendered.html")'
ls -lh test_best_visual_rendered.html
```

## Minimal verification checklist (must pass)

1. Render `test_best_visual.Rmd` successfully.
2. In the output map:
   - Kosovo is visible as its own region.
   - Somalia polygons appear correctly.
   - Cyprus polygons appear correctly.
3. The rest of the visual output matches the expected look:
   - Same background and styling
   - Same titles and spacing
   - Same color scale and legend behavior

## Diagnostic checks Codex should run

### Confirm GeoJSON contains required ISO-3 keys

```bash
cd /workspaces/TestRepo
R -q -e 'library(jsonlite); world_geojson <- jsonlite::fromJSON("world.geojson", simplifyVector = FALSE); geo_iso <- vapply(world_geojson$features, function(f) f$properties$iso_a3, character(1)); cat("Feature count:", length(geo_iso), "\n"); cat("Has XKX:", "XKX" %in% geo_iso, "\n"); cat("Has CYP:", "CYP" %in% geo_iso, "\n"); cat("Has SOM:", "SOM" %in% geo_iso, "\n")'
```

Note: If `world.geojson` is not a repo file, adjust the path to the actual GeoJSON used inside `test_best_visual.Rmd`.

### Confirm the locations key matches the GeoJSON feature id key

Codex must identify:
- What `locations` column is used in the Plotly choropleth
- What `featureidkey` is set to (for example `properties.iso_a3`)

Then ensure the `locations` values match the GeoJSON feature ids for Kosovo, Somalia, and Cyprus.

### Spot-check for `-99` codes in the data used for plotting

```bash
cd /workspaces/TestRepo
R -q -e 'library(dplyr); df <- read.csv("life-expectancy-filtered.csv"); print(df %>% filter(Code == "-99") %>% distinct(Entity) %>% head(50))'
```

If the plot uses a different dataset or processed frame, run the check on that object instead.

## Output and PR expectations

- Do not commit `test_best_visual_rendered.html` if it is large.
- Changes should be limited to code needed to make Kosovo, Somalia parts, and Cyprus parts appear.
- Every attempt must update `report.txt` with details and results.

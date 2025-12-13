# Testing and Validation

## Goal
Fix missing polygons for:
- Kosovo
- Northern Cyprus (as part of Cyprus)
- Somaliland (as part of Somalia)

Design and layout must not change.

## How to render
From repo root:

R -q -e 'rmarkdown::render("test_best_visual.Rmd", output_file="__codex_render.html")'

## Required checks (programmatic)
Run these in R after loading the same GeoJSON object used by the plot:

1) Kosovo code alignment
- Confirm dataset rows for Entity == "Kosovo" use Code == "XKX" for all years used by the animation.
- Confirm GeoJSON contains a feature with properties.iso_a3 == "XKX".

2) Cyprus completeness
- Identify GeoJSON features whose name indicates Northern Cyprus.
- Confirm their properties.iso_a3 is "CYP" after the fix.

3) Somalia completeness
- Identify GeoJSON features whose name indicates Somaliland.
- Confirm their properties.iso_a3 is "SOM" after the fix.

## Required checks (visual)
Open __codex_render.html and verify:
- Kosovo is filled when neighboring countries are filled
- The northern part of Cyprus is filled, not blank
- Somaliland region is filled, not blank

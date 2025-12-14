# Carry-forward strategy for irregular country time series

This note describes a simple approach to display country values across all years even when the source data is sparse or unevenly spaced. The goal is to carry the most recent available value forward until a new value appears so the map has continuous coverage without gaps.

## Core idea
- For each country, keep its records ordered by year.
- Whenever a year is missing, reuse (carry forward) the last known value from an earlier year.
- When a new recorded value appears, start carrying forward that newer value until the next update.

## Step-by-step algorithm
1. **Normalize keys**
   - Ensure country identifiers are consistent (e.g., ISO3 codes) and years are integers.
   - Remove obvious duplicates and handle special cases (e.g., custom codes like `XKX` for Kosovo) before interpolation.

2. **Create a complete year grid per country**
   - Determine the global year range (e.g., 1543 to the latest year).
   - For each country, build a full sequence of years within that range. Include years with no observations so they can be filled.

3. **Merge observed data onto the grid**
   - Left-join the country’s observed records onto its full year grid. This produces `NA` for years with no observation.
   - If historical data is five-yearly until ~1850 and yearly afterward, the join will reflect those sparsely populated early years automatically.

4. **Carry forward the last value**
   - Within each country, sort by year and fill missing values using last observation carried forward (LOCF).
   - If the country has no earlier observation (e.g., a brand-new country), keep `NA` until the first real record appears—no value is fabricated before the first observation.

5. **Handle irregular overlaps**
   - Some countries have out-of-pattern entries (e.g., a single mid-period year). The LOCF pass carries that value forward to later years until a newer observation appears.
   - Do **not** carry values backward in time; respect the actual first observation.

6. **Combine all countries**
   - Bind the per-country filled grids back together. Each country now has values for every year after its first observation, ensuring continuous map coverage.

7. **Optional safeguards**
   - Keep a column that marks whether a value was observed or carried forward for transparency.
   - When rendering animations, filter to years where at least one country has non-`NA` data to avoid empty frames.

## Pseudocode outline
- Group data by `country_code`.
- For each group: create full year sequence, join observations, sort, then fill with LOCF (no backward fill).
- Recombine groups; use the filled column for plotting.

## Practical considerations
- **Performance:** Vectorized fills (e.g., `dplyr::group_modify` with `tidyr::complete` + `fill`) scale well for thousands of country-year rows.
- **Edge cases:**
  - Countries with gaps after their last observation will show their final value indefinitely. Optionally cap at a maximum year if desired.
  - Historical entity changes (country splits/merges) may require remapping codes before filling so the carry-forward path matches the intended lineage.
- **Verification:**
  - Spot-check a few countries (e.g., Great Britain) across early and late periods to confirm values persist during unrecorded years.
  - Ensure the filled dataset’s earliest non-`NA` year per country matches the original data; only forward filling was applied.

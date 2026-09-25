# The maths

Accessible derivations for the analytics in this engine. Notation: reflectances
are unitless surface reflectances in [0, 1]; NaN = masked/nodata.

## Vigor indices

**NDVI** — normalised difference vegetation index:

    NDVI = (NIR − red) / (NIR + red)

Healthy leaves reflect NIR strongly and absorb red; the ratio lands near
+0.8 for dense canopy, near 0 for bare soil, negative for water. It
*saturates*: past leaf-area index ≈ 3–4, adding more leaves barely moves it.

**EVI** — enhanced vegetation index, resists saturation and aerosol haze:

    EVI = 2.5 · (NIR − red) / (NIR + 6·red − 7.5·blue + 1)

The blue band corrects aerosol scattering in red; the +1 canopy-background
term and 2.5 gain keep the range comparable to NDVI.

**SAVI** — soil-adjusted vegetation index, for sparse cover where bright
soil leaks into the signal:

    SAVI = ((NIR − red) / (NIR + red + L)) · (1 + L),  L = 0.5

**MSAVI2** — same idea, but L is solved per-pixel instead of fixed:

    MSAVI = (2·NIR + 1 − √((2·NIR+1)² − 8·(NIR − red))) / 2

**GNDVI** — green NDVI, swaps red for green:

    GNDVI = (NIR − green) / (NIR + green)

More sensitive to chlorophyll concentration, so it picks up nitrogen stress
earlier than NDVI — at the cost of saturating sooner.

All five are NaN-honest: a NaN input or zero denominator yields NaN, never
a fabricated value.

## Phenology-aware anomalies

For a pass on day-of-year *d* in year *y*, zone *z*, index *i*:

- **Baseline** = { values of (z, i) from years < y with |doy − d| ≤ 15 days,
  wrapping around New Year }.
- **z = (value − baseline mean) / baseline std** (sample std, n ≥ 2).
- **Stressed** iff z ≤ −2.0 (configurable).

Comparing June only to prior Junes removes the seasonal cycle from the
signal — a raw year-round z-score would flag every winter as an anomaly.
The first year of history always reports "insufficient history" rather than
a verdict.

## Season metrics

Let the year's series be (t₁,v₁)…(tₙ,vₙ), amplitude A = max(v) − min(v).

- **Green-up**: first date the rising edge crosses min(v) + 0.5·A
  (mid-green-up; the fraction is configurable).
- **Peak**: date of max(v).
- **Senescence**: first date after the peak the falling edge crosses the
  same level (mid-senescence).
- **Season integral**: trapezoidal area under the polyline between
  green-up and senescence, in index·days — a proxy for total seasonal
  productivity.
- **Integral z-score**: the year's integral z-scored against prior years'
  integrals (needs ≥ 2 prior seasons).

Crossings between passes are linearly interpolated, so dates aren't
quantised to the pass grid.

## Zonal statistics

Mean, median, std, min, max, p10, p90 over finite pixels inside the zone
mask. p10/p90 are robust to the odd unmasked cloud or shadow the mean
would absorb.

# Changelog

## v0.1.0 — 2026-09-25

Initial release: the vegetation/vigor analytics engine for earthwatch-suite.

- Vigor indices: NDVI/EVI/SAVI reused from survey-imagery's registry
  (lazy import, never reimplemented); GNDVI/MSAVI defined here
- Per-zone per-pass vigor time series with incremental CSV appends
- Phenology-aware (day-of-year) z-score anomaly detection with stressed flags
- Growing-season summaries: green-up, peak, senescence, season integral + z
- Per-pixel vigor-class maps (uint8 GeoTIFF + paletted QGIS .qml)
- Real STAC acquisition path via survey-imagery; seeded `--synthetic` demo
  mode for the whole pipeline with zero network
- 52 tests passing

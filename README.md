> [!IMPORTANT]
> **Consolidated into [EarthWatch-Suite](https://github.com/crieck2010/earthwatch-suite)**  
> This engine has been consolidated into the unified [EarthWatch-Suite monorepo](https://github.com/crieck2010/earthwatch-suite). Active development, bug fixes, releases, and unified testing now live in earthwatch-suite. This repository is preserved as an archive.

# survey-vegetation

> **Part of [earthwatch-suite](https://github.com/crieck2010/earthwatch-suite)** —
> the remote-sensing project (satellite imagery, change detection, site
> monitoring). Terrestrial surveying lives in
> [survey-suite](https://github.com/crieck2010/survey-suite); the two stay
> compatible through the
> [cross-suite contracts](https://github.com/crieck2010/earthwatch-suite/blob/main/docs/CONTRACTS.md).

The **vegetation/vigor analytics engine** for earthwatch-suite: per-zone
vigor-index time series, phenology-aware anomaly detection, growing-season
summaries, and per-pixel vigor-class maps from satellite imagery.

It does **not** reimplement spectral indices. NDVI/EVI/SAVI come from
survey-imagery's index registry (lazy import, reused); this package adds
GNDVI/MSAVI plus the vegetation-specific analytics on top: zonal series,
day-of-year anomalies, season metrics, and vigor classification.

## Quickstart (no network — synthetic demo)

```bash
pip install survey-vegetation
survey-vegetation demo --out-dir ./veg-demo
```

That runs the full pipeline on seeded synthetic data: three demo zones
(orchard, pasture, woodlot) over 2022–2024, one planted drought anomaly in
the orchard in summer 2024, and prints what it found:

```
[1/5] timeseries: 378 records -> ./veg-demo/timeseries.csv
[2/5] anomalies: 378 records, 19 stressed -> ./veg-demo/anomalies.csv
[3/5] season: 18 summaries -> ./veg-demo/season.json
[4/5] vigor map: vigor_classes.npy + .qml
[5/5] demo complete in ./veg-demo
```

## What it does

| Command | Input | Output |
|---|---|---|
| `timeseries` | zones GeoJSON + date range (or `--synthetic`) | per-zone per-pass vigor CSV, appended incrementally |
| `anomalies` | time-series CSV | phenology-aware z-score anomalies CSV, stressed flags |
| `season` | time-series CSV | growing-season JSON per zone/year |
| `vigor-map` | index raster (or `--synthetic`) | vigor-class GeoTIFF + QGIS `.qml` |
| `demo` | nothing | the whole pipeline on synthetic data |
| `indices` | nothing | vigor indices and their required bands |

## Installation

Requires Python 3.9+ and numpy.

```bash
pip install survey-vegetation            # core (numpy only)
pip install "survey-vegetation[acquire]" # + survey-imagery (real STAC acquisition)
pip install "survey-vegetation[raster]"  # + rasterio (GeoTIFF in/out)
pip install "survey-vegetation[full]"    # everything
```

## Real satellite data

`timeseries` without `--synthetic` pulls Sentinel-2 (default) through
survey-imagery's STAC pipeline — one monitor run per zone, per-scene
statistics converted to the zone time-series schema:

```bash
survey-vegetation timeseries --zones fields.geojson \
  --start 2023-01-01 --end 2024-12-31 --indices ndvi,evi,savi \
  --out timeseries.csv
survey-vegetation anomalies --timeseries timeseries.csv --out anomalies.csv
survey-vegetation season --timeseries timeseries.csv --out season.json
```

Zones are a GeoJSON FeatureCollection of Polygons (see `examples/zones.geojson`).

## Suite integration

- **survey-monitor**: the time-series CSV is the contract the monitor
  watches. Create one monitor site per zone with the same index list and
  threshold the `mean` column — see `docs/TIMESERIES_SCHEMA.md` for the
  column mapping.
- **survey-change**: vigor-class rasters are integer class maps; diff two
  dates with survey-change for transition matrices (e.g. vigorous →
  stressed area per zone).
- **survey-qgis**: drag the vigor-class `.tif` into QGIS and apply the
  companion `.qml` — paletted symbology, no setup.

```python
# Python API
from vegetation import synthetic, timeseries, anomalies, season, vigor

zones = synthetic.synthetic_zones()
records = synthetic.synthetic_timeseries(zones)
timeseries.append_csv(records, "ts.csv")
stressed = [r for r in anomalies.detect_anomalies(records, "ndvi") if r.stressed]
summaries = season.summarize_all_years(records, "ndvi")
classes = vigor.classify(synthetic.synthetic_index_raster())
```

## The maths

Full derivations live in `docs/MATHS.md`. The short version:

- **Vigor indices** — NDVI = (NIR−red)/(NIR+red); EVI adds a blue-band
  aerosol correction and resists saturation over dense canopy; SAVI/MSAVI
  correct for bright soil backgrounds; GNDVI swaps red for green and tracks
  chlorophyll/nitrogen stress. See `docs/MATHS.md` for formulas.
- **Phenology-aware anomalies** — for each pass, the baseline is the same
  zone's values from *prior years* within ±15 days of day-of-year (June is
  compared to Junes, never to January). z = (value − baseline mean) /
  baseline std; z ≤ −2 flags a stressed zone.
- **Season metrics** — green-up/senescence are the dates the curve crosses
  50% of the seasonal amplitude (mid-green-up convention, configurable);
  the season integral is the trapezoidal area under the curve between them,
  a proxy for total seasonal productivity, z-scored against prior years.

## Limitations

- **Index saturation**: NDVI flattens above LAI ≈ 3–4; use EVI for dense
  canopies.
- **Soil background**: sparse cover mixes soil signal into every index —
  SAVI/MSAVI mitigate, they don't eliminate.
- **Cloud gaps**: the series is only as continuous as the clear passes;
  long gaps bias green-up/senescence dates.
- **Anomalies need history**: ≥1 prior year (2+ samples) before z-scores
  are meaningful; the first year always reports "insufficient history".
  Off-season z-scores can be noisy when the baseline hovers near zero —
  filter on `value`/`baseline_mean` if you only care about the growing season.
- **Thresholds are defaults**: the vigor bands are tuned for NDVI in
  temperate agriculture — adjust per crop/index (see
  `docs/VIGOR_CLASSES.md`).
- **Not agronomy advice**: this is a remote-sensing screening tool, not a
  substitute for ground truth.

## Layout

```
src/vegetation/   engine (stdlib + numpy core)
  indices_ext.py  vigor indices (registry reuse + GNDVI/MSAVI)
  zones.py        GeoJSON zone loading
  zonal.py        pure-numpy zonal statistics
  timeseries.py   per-zone per-pass records + incremental CSV
  anomalies.py    phenology-aware z-score anomalies
  season.py       growing-season summaries
  vigor.py        vigor-class maps
  qml.py          QGIS paletted styles
  synthetic.py    seeded synthetic data (demo + tests)
  acquire.py      real STAC acquisition via survey-imagery
  cli.py          survey-vegetation CLI
tests/            pytest (no network)
docs/             schemas, vigor-class spec, maths
examples/         zones.geojson, run_demo.sh
```

## License

MIT — see [LICENSE](LICENSE).

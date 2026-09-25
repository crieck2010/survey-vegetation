# Time-series schema

`timeseries.csv` is the central interchange file of survey-vegetation — and
the contract **survey-monitor** watches. One row per (zone, pass, index).

## Columns

| Column | Type | Meaning |
|---|---|---|
| `zone_id` | string | Zone id from the zones GeoJSON (stable key) |
| `zone_name` | string | Human-readable zone name |
| `pass_id` | string | Pass/scene id (`synthetic-YYYY-MM-DD` in demo mode) |
| `date` | ISO date | Acquisition date |
| `doy` | int | Day of year (1–366) |
| `year` | int | Calendar year |
| `index` | string | Vigor index (`ndvi`, `evi`, `savi`, `gndvi`, `msavi`) |
| `mean` | float | **Zonal mean — the column survey-monitor thresholds** |
| `median` | float | Zonal median |
| `std` | float | Zonal standard deviation |
| `minimum` | float | Zonal minimum |
| `maximum` | float | Zonal maximum |
| `p10` / `p90` | float | 10th / 90th percentile |
| `valid_pixels` | int | Pixels that contributed (finite, inside zone) |
| `total_pixels` | int | Pixels inside the zone |
| `cloud_cover` | float? | Scene cloud cover %, if known |

Columns are append-only: readers must tolerate (ignore) trailing columns
they don't know, and writers must never reorder or rename.

## Incremental appends

Re-running `timeseries` with a later end date appends only new passes.
Dedupe key: `(zone_id, pass_id, index)` — re-appending the same records is
a no-op.

## Mapping to a survey-monitor site config

One monitor site per zone:

```yaml
site_id: orchard-north
# footprint: the zone polygon (same GeoJSON)
indices:
  - name: ndvi
    metric: mean            # <- this CSV column
    warning: {delta: 0.10, direction: down}
    critical: {delta: 0.20, direction: down}
```

The monitor's per-pass `value` is the row's `mean` for the matching
`(zone_id → site_id, index)`; its baseline/delta/z-score logic then applies
unchanged. See survey-monitor's `docs/SITE_CONFIG.md` for the full schema.

## Anomalies CSV

`anomalies.csv` columns: `zone_id, zone_name, index, date, doy, year,
value, baseline_mean, baseline_std, baseline_n, baseline_years, z_score,
stressed, window_days`. `z_score` is empty when history is insufficient
(the `note` field in the Python record explains why).

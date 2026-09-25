# Vigor-class specification

`vigor-map` bins a vigor-index raster into integer classes. The raster is a
`uint8` GeoTIFF (`255` = nodata) with a paletted `.qml` sidecar; class ids
are stable so **survey-change** can diff two dates into transition matrices.

## Default bands (NDVI)

| Class id | Label | NDVI range | Colour |
|---|---|---|---|
| 0 | Water / shadow | < 0.0 | deep blue |
| 1 | Bare soil | 0.0 – 0.2 | tan |
| 2 | Stressed | 0.2 – 0.4 | yellow |
| 3 | Moderate | 0.4 – 0.6 | light green |
| 4 | Vigorous | 0.6 – 0.8 | green |
| 5 | Very dense | ≥ 0.8 | dark green |

Ranges are lower-inclusive, upper-exclusive. These defaults are tuned for
**NDVI in temperate agriculture** — they are a starting point, not a law.

## When to adjust

- **EVI/SAVI**: same shape, slightly compressed range — shift boundaries
  down ~0.05–0.1 or calibrate against known fields.
- **Arid / bright soils**: raise the bare/stressed boundary; consider MSAVI
  as the input index instead of NDVI.
- **Dense canopy (orchards, forest)**: NDVI saturates — the vigorous/very
  dense split carries little information; EVI separates better.
- **Crop-specific**: calibrate boundaries against ground-truth scouting for
  each crop; document the chosen thresholds alongside the product.

Pass custom bands to `vegetation.vigor.classify(index_array, bands=[...])`
with the same `(id, label, lo, hi, rgba)` tuple shape.

## Use with survey-change

Two class rasters (t0, t1) → survey-change transition matrix gives per-zone
change areas, e.g. "12.4 ha went vigorous → stressed between June and
August". Because class ids are stable integers, no reclassification is
needed.

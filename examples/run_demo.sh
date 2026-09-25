#!/bin/bash
# End-to-end synthetic demo: no network, no data files needed.
set -e
OUT="${1:-./veg-demo}"
survey-vegetation demo --out-dir "$OUT" --seed 7
echo "---"
echo "Next: open $OUT/timeseries.csv, or run the steps individually:"
echo "  survey-vegetation anomalies --timeseries $OUT/timeseries.csv --out anomalies.csv"
echo "  survey-vegetation season    --timeseries $OUT/timeseries.csv --out season.json"

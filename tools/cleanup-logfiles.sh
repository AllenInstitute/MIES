#!/bin/sh

set -e

find "$APPDATA/WaveMetrics" -type f -iname Log.jsonl -exec rm {} \;

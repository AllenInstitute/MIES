#!/bin/sh

IFS=$'\n'

set -e

files=$(find "$APPDATA/WaveMetrics" -type f -iname Log.jsonl)

for i in $files
do
  name=$(echo $i | sed -e "s/.*WaveMetrics\/Igor Pro /IP/g" -e "s/Packages\///g" -e "s/\//_/g")
  cp "$i" "$name"
done

folders=$(find "$APPDATA/WaveMetrics" -type d -iname Diagnostics)

for i in $folders
do
  name=$(echo $i | sed -e "s/.*WaveMetrics\/Igor Pro /IP/g" -e "s/\//_/g")
  cp -r "$i" "$name"
done

# now that we have successfully copied both logfiles and diagnostics, we can
# safely remove them
rm --verbose $files

for i in $folders
do
  rm --verbose --dir $i/* 2> /dev/null || true
done

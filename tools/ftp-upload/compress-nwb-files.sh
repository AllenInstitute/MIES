#!/bin/bash

cd $1

for dir in test-itc18-assets test-itc1600-assets test-ni-assets
do
  if [ -n "$(find "$dir" -maxdepth 0 -type d -empty)" ]
  then
    continue
  fi

  tar --remove-files --use-compress-program=zstd -cvf $dir/NWB.tar.zst $dir/*nwb
done

#!/bin/bash

cd $1

for dir in TestNI-* TestITC18-* TestITC1600-*
do
  if [ ! -d $dir ]
  then
    continue
  elif [ -n "$(find "$dir" -maxdepth 0 -type d -empty)" ]
  then
    continue
  fi

  tar --remove-files --use-compress-program=zstd -cvf $dir/NWB.tar.zst $dir/*nwb

  tar --remove-files --use-compress-program=zstd -cvf $dir/CoberturaAndJUNIT.tar.zst $dir/*xml
done

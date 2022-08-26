#!/bin/sh

if [ "$#" -eq 0 ]
then
  echo "Missing parameter IP_\${version}_(32|64)." 1>&2
  exit 1
fi

versionString=$1
version=$(echo $versionString | cut -f 2 -d "_")
bitness=$(echo $versionString | cut -f 3 -d "_")

if [ $bitness -eq 32 ]
then
  suffix="IgorBinaries_Win32/Igor.exe"
elif [ $bitness -eq 64 ]
then
  suffix="IgorBinaries_x64/Igor64.exe"
else
  echo "Invalid bitness" > /dev/stderr
  exit 1
fi

case $MSYSTEM in
  MINGW*)
    echo "/c/Program Files/WaveMetrics/Igor Pro $version Folder/$suffix"
    ;;
  *)
    echo "C:/Program Files/WaveMetrics/Igor Pro $version Folder/$suffix"
    ;;
esac

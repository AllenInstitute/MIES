#!/bin/sh

if [ "$#" -eq 0 ]
then
  echo "Missing parameter IP_\${version}_(32|64)." 1>&2
  exit 1
fi

versionString=$1
version=$(echo $versionString | cut -f 2 -d "_")
bitness=$(echo $versionString | cut -f 3 -d "_")

if [ "$CI_IGOR_REVISION" = "" ]; then
  revision=""
else
  revision="_$CI_IGOR_REVISION"
fi

if [ $bitness -eq 32 ]
then
  suffix="IgorBinaries_Win32$revision/Igor.exe"
elif [ $bitness -eq 64 ]
then
  suffix="IgorBinaries_x64$revision/Igor64.exe"
else
  echo "Invalid bitness" > /dev/stderr
  exit 1
fi

case $OS in
  Windows*)
    echo "/c/Program Files/WaveMetrics/Igor Pro $version Folder/$suffix"
    ;;
  *)
    echo "C:/Program Files/WaveMetrics/Igor Pro $version Folder/$suffix"
    ;;
esac

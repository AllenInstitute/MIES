#!/bin/sh

# Perform a clean MIES installation
# Uses the files from the release package

set -e

if [ "$#" -gt 0 -a "$1" = "skipHardwareXOPs" ]
then
  installHWXOPs=0
else
  installHWXOPs=1
fi

git --version > /dev/null
if [ $? -ne 0 ]
then
  echo "Could not find git executable"
  exit 1
fi

top_level=$(git rev-parse --show-toplevel)

if [ ! -d "$top_level" ]
then
  echo "Could not find git repository"
  exit 1
fi

case $MSYSTEM in
  MINGW*)
      UNZIP_EXE="$top_level/tools/unzip.exe"
      IGOR_USER_FILES="$USERPROFILE/Documents/WaveMetrics/Igor Pro 7 User Files"
      installNIDAQmxXOP=1
      ;;
    *)
      UNZIP_EXE=unzip
      IGOR_USER_FILES="$HOME/WaveMetrics/Igor Pro 7 User Files"
      installNIDAQmxXOP=0
      ;;
esac

rm -rf "$IGOR_USER_FILES"

user_proc="$IGOR_USER_FILES/User Procedures"
igor_proc="$IGOR_USER_FILES/Igor Procedures"
xops="$IGOR_USER_FILES/Igor Extensions (64-bit)"
xops_help="$IGOR_USER_FILES/Igor Help Files"

mkdir -p "$user_proc"
mkdir -p "$igor_proc"
mkdir -p "$xops_help"

# install unit-testing package
cp -r  "$top_level"/Packages/unit-testing "$user_proc"

release_pkg=`ls Release*.zip`

if [ ! -e "$release_pkg" ]
then
  echo "Could not find a release package"
  exit 1
fi

folder=release_zip_extracted

rm -rf $folder

# install files from release package
"$UNZIP_EXE" "$release_pkg" -d $folder

rm -rf "$folder"/Packages/doc/html
cp -r  "$folder"/Packages/*  "$user_proc"
cp -r  "$folder"/HelpFiles-IP7/* "$xops_help"
cp "$folder"/version.txt "$IGOR_USER_FILES"

mkdir -p "$xops"

if [ "$installHWXOPs" = "1" ]
then
  cp -r  "$folder"/XOPs-IP7-64bit/*  "$xops"
  cp -r  "$folder"/XOP-tango-IP7-64bit/*  "$xops"
  # the NIDAQ XOP is not in the release package so we need to cheat a bit
  if [ "$installNIDAQmxXOP" = "1" ]
  then
    cp "$top_level/XOPs-IP7-64bit/NIDAQmx.*" "$xops"
  fi
else
  cp -r  "$folder"/XOPs-IP7-64bit/HDF5*  "$xops"
  cp -r  "$folder"/XOPs-IP7-64bit/MIESUtils*  "$xops"
fi

exit 0

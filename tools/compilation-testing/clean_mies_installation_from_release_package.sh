#!/bin/sh

# Perform a clean MIES installation
# Uses the files from the release package

set -e

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
      ;;
    *)
      UNZIP_EXE=unzip
      IGOR_USER_FILES="$HOME/WaveMetrics/Igor Pro 7 User Files"
      ;;
esac

rm -rf "$IGOR_USER_FILES"

user_proc="$IGOR_USER_FILES/User Procedures"
igor_proc="$IGOR_USER_FILES/Igor Procedures"
xops="$IGOR_USER_FILES/Igor Extensions (64-bit)"
xops_help="$IGOR_USER_FILES/Igor Help Files"

mkdir -p "$user_proc"
mkdir -p "$igor_proc"
mkdir -p "$xops"
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
cp -r  "$folder"/XOPs-IP7-64bit/*  "$xops"
cp -r  "$folder"/XOP-tango-IP7-64bit/* "$xops"
cp -r  "$folder"/HelpFiles-IP7/* "$xops_help"

exit 0

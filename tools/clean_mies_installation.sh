#!/bin/bash

# Install MIES with potentially skipping the hardware XOPs. The installation is
# either down from the git repo, from the release package or the installer itself.

usage()
{
  echo "Usage: $0 [-x skipHardwareXOPs] [-s [git|release|installer]]" 1>&2
  exit 1
}

skipHardwareXOPs=0
sourceLoc=git

while getopts ":x:s:" o; do
    case "${o}" in
        x)
            if [ "${OPTARG}" = "skipHardwareXOPs" ]
            then
              skipHardwareXOPs=1
            else
              usage
            fi
            ;;
        s)
            if [ "${OPTARG}" = "git" ]
            then
              sourceLoc=git
            elif [ "${OPTARG}" = "release" ]
            then
              sourceLoc=release
            elif [ "${OPTARG}" = "installer" ]
            then
              sourceLoc=installer
            else
              usage
            fi
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

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
      ;;
    *)
      UNZIP_EXE=unzip
      ;;
esac

if [ "$sourceLoc" = "git" ]
then
  base_folder=$top_level
elif [ "$sourceLoc" = "release" ]
then
  release_pkg=$(ls Release*.zip)

  if [ ! -e "$release_pkg" ]
  then
    echo "Could not find a release package"
    exit 1
  fi

  base_folder=release_zip_extracted

  rm -rf $base_folder

  # install files from release package
  "$UNZIP_EXE" "$release_pkg" -d $base_folder
elif [ "$sourceLoc" = "installer" ]
then
  base_folder=$top_level
fi

versions="8 9"

for i in $versions
do
  case $MSYSTEM in
    MINGW*)
        IGOR_USER_FILES="$USERPROFILE/Documents/WaveMetrics/Igor Pro ${i} User Files"
        ;;
      *)
        IGOR_USER_FILES="$HOME/WaveMetrics/Igor Pro ${i} User Files"
        ;;
  esac

  rm -rf "$IGOR_USER_FILES"

  user_proc="$IGOR_USER_FILES/User Procedures"
  igor_proc="$IGOR_USER_FILES/Igor Procedures"
  xops64="$IGOR_USER_FILES/Igor Extensions (64-bit)"
  xops32="$IGOR_USER_FILES/Igor Extensions"

  mkdir -p "$user_proc"

  # install testing files from git repo
  mkdir -p "$user_proc/unit-testing"
  cp -r  "$top_level"/Packages/unit-testing/procedures "$user_proc/unit-testing"
  cp -r  "$top_level"/Packages/Testing-MIES  "$user_proc"

  if [ "$sourceLoc" = "installer" ]
  then
    # requires an installer which does not trigger UAC
    if [ "$skipHardwareXOPs" = "1" ]
    then
      MSYS_NO_PATHCONV=1 $base_folder/MIES-*.exe /S /CIS /SKIPHWXOPS
    else
      MSYS_NO_PATHCONV=1 $base_folder/MIES-*.exe /S /CIS
    fi

    # move shortcut to the main include file
    # into user procedures so that we can compilation test it
    mv "$igor_proc"/MIES_include.lnk "$user_proc"
    continue
  fi

  if [ $i -le 8 ]
  then
    cp -r  "$base_folder"/Packages/HDF-IP${i}  "$user_proc"
  fi

  cp -r  "$base_folder"/Packages/Arduino  "$user_proc"
  cp -r  "$base_folder"/Packages/IPNWB  "$user_proc"
  cp -r  "$base_folder"/Packages/MIES_include.ipf  "$user_proc"
  cp -r  "$base_folder"/Packages/MIES  "$user_proc"
  cp -r  "$base_folder"/Packages/Settings  "$user_proc"
  cp -r  "$base_folder"/Packages/Stimsets  "$user_proc"

  mkdir -p "$user_proc/ZeroMQ"
  cp -r  "$base_folder"/Packages/ZeroMQ/procedures  "$user_proc/ZeroMQ"

  mkdir -p "$user_proc/ITCXOP2"
  cp -r  "$base_folder"/Packages/ITCXOP2/tools "$user_proc/ITCXOP2"

  mkdir -p "$xops32" "$xops64"

  if [ "$skipHardwareXOPs" = "0" ]
  then
    cp -r  "$base_folder"/XOPs-IP${i}/*  "$xops32"
    cp -r  "$base_folder"/XOPs-IP${i}-64bit/*  "$xops64"
  else
    if [ $i -le 8 ]
    then
      cp -r  "$base_folder"/XOPs-IP${i}/HDF5*  "$xops32"
      cp -r  "$base_folder"/XOPs-IP${i}-64bit/HDF5*  "$xops64"
    fi

    cp -r  "$base_folder"/XOPs-IP${i}/MIESUtils*  "$xops32"
    cp -r  "$base_folder"/XOPs-IP${i}-64bit/MIESUtils*  "$xops64"
  fi

  if [ "$sourceLoc" = "git" ]
  then
    echo "Release: FAKE MIES VERSION" > "$IGOR_USER_FILES"/version.txt
  elif [ "$sourceLoc" = "release" ]
  then
    cp "$base_folder"/version.txt "$IGOR_USER_FILES"
  fi
done

exit 0

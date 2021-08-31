#!/bin/bash

set -e

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

wavemetrics_home="$USERPROFILE/Documents/WaveMetrics"

rm -rf "$wavemetrics_home"

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

  # requires an installer which does not trigger UAC
  # installer always installs for all available and supported IP versions
  if [ "$skipHardwareXOPs" = "1" ]
  then
    MSYS_NO_PATHCONV=1 $base_folder/MIES-*.exe /S /CIS /SKIPHWXOPS
  else
    MSYS_NO_PATHCONV=1 $base_folder/MIES-*.exe /S /CIS
  fi
fi

versions="8 9"

for i in $versions
do
  igor_user_files="$wavemetrics_home/Igor Pro ${i} User Files"
  user_proc="$igor_user_files/User Procedures"
  igor_proc="$igor_user_files/Igor Procedures"
  xops64="$igor_user_files/Igor Extensions (64-bit)"
  xops32="$igor_user_files/Igor Extensions"

  mkdir -p "$user_proc"

  # install testing files from git repo
  mkdir -p "$user_proc/unit-testing"
  cp -r  "$top_level"/Packages/unit-testing/procedures "$user_proc/unit-testing"
  cp -r  "$top_level"/Packages/Testing-MIES  "$user_proc"
  cp -r  "$top_level"/Packages/doc/ipf  "$user_proc"

  if [ "$sourceLoc" = "installer" ]
  then
    # move shortcut to the main include file
    # into user procedures so that we can compilation test it
    mv "$igor_proc"/MIES_Include.lnk "$user_proc"
    continue
  fi

  if [ $i -le 8 ]
  then
    cp -r  "$base_folder"/Packages/HDF-IP${i}  "$user_proc"
  fi

  cp -r  "$base_folder"/Packages/Arduino  "$user_proc"
  cp -r  "$base_folder"/Packages/IPNWB  "$user_proc"
  cp -r  "$base_folder"/Packages/MIES_Include.ipf  "$user_proc"
  cp -r  "$base_folder"/Packages/MIES  "$user_proc"
  cp -r  "$base_folder"/Packages/Settings  "$user_proc"
  cp -r  "$base_folder"/Packages/Stimsets  "$user_proc"

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

    cp -r  "$base_folder"/XOPs-IP${i}/JSON*  "$xops32"
    cp -r  "$base_folder"/XOPs-IP${i}-64bit/JSON*  "$xops64"

    cp -r  "$base_folder"/XOPs-IP${i}/ZeroMQ*  "$xops32"
    cp -r  "$base_folder"/XOPs-IP${i}/libzmq*  "$xops32"
    cp -r  "$base_folder"/XOPs-IP${i}-64bit/ZeroMQ*  "$xops64"
    cp -r  "$base_folder"/XOPs-IP${i}-64bit/libzmq*  "$xops64"
  fi

  if [ "$sourceLoc" = "git" ]
  then
    echo "Release: FAKE MIES VERSION" > "$igor_user_files"/version.txt
  elif [ "$sourceLoc" = "release" ]
  then
    cp "$base_folder"/version.txt "$igor_user_files"
  fi
done

exit 0

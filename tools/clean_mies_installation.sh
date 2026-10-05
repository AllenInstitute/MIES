#!/bin/bash

set -e

# Install MIES with potentially skipping the hardware XOPs. The installation is
# either done from the git repo, from the release package or the installer itself.

usage()
{
  echo "Usage: $0 [-x skipHardwareXOPs] [-s [git|release|installer]]" 1>&2
  exit 1
}

# Usage: mklnk TARGET SHORTCUT_PATH
# TARGET can be a file or a directory.
# Example: mklnk ~/Projects ~/Desktop/Projects
#          mklnk ~/bin/tool.exe ~/Desktop/Tool
mklnk() {
    if [[ $# -ne 2 ]]; then
        echo "usage: mklnk TARGET SHORTCUT_PATH" >&2
        return 1
    fi
    [[ -e $1 ]] || { echo "mklnk: no such file or directory: $1" >&2; return 1; }

    local target workdir shortcut="$2"
    [[ $shortcut == *.lnk ]] || shortcut+=".lnk"

    target=$(cygpath -wa "$1") || return 1
    shortcut=$(cygpath -wa "$shortcut") || return 1

    # Folders: "Start in" is the folder itself; files: their parent folder
    if [[ -d $1 ]]; then
        workdir=$target
    else
        workdir=$(cygpath -wa "$(dirname -- "$1")") || return 1
    fi

    # Escape single quotes for PowerShell ('' inside '...')
    target=${target//\'/\'\'}
    workdir=${workdir//\'/\'\'}
    shortcut=${shortcut//\'/\'\'}

    powershell.exe -NoProfile -Command "
        \$s = (New-Object -ComObject WScript.Shell).CreateShortcut('$shortcut');
        \$s.TargetPath = '$target';
        \$s.WorkingDirectory = '$workdir';
        \$s.Save()
    "
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

case $OS in
  Windows*)
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

  # remove old installations
  rm -rf "$USERPROFILE/Documents/MIES/"

  # requires an installer which does not trigger UAC
  # installer always installs for all available and supported IP versions
  installPath="$(find "$base_folder" -name "MIES-*.exe")"
  if [ "$skipHardwareXOPs" = "1" ]
  then
    MSYS_NO_PATHCONV=1 $installPath /S /CIS /SKIPHWXOPS
  else
    MSYS_NO_PATHCONV=1 $installPath /S /CIS
  fi
fi

versions="9 10"

for i in $versions
do
  igor_user_files="$wavemetrics_home/Igor Pro ${i} User Files"
  user_proc="$igor_user_files/User Procedures"
  igor_proc="$igor_user_files/Igor Procedures"
  xops64="$igor_user_files/Igor Extensions (64-bit)"

  mkdir -p "$user_proc"

  # install testing files from git repo
  mklnk "$top_level"/Packages/igortest/procedures "$user_proc/igortest"
  mklnk "$top_level"/Packages/tests  "$user_proc/tests"
  mklnk "$top_level"/Packages/doc/ipf  "$user_proc/ipf"

  # only install to $user_proc as it contains specialized igor hooks
  mklnk "$top_level"/Packages/conversion  "$user_proc/conversion"

  if [ "$sourceLoc" = "installer" ]
  then
    # move shortcut to the main include file
    # into user procedures so that we can compilation test it
    mv "$igor_proc"/MIES_Include.lnk "$user_proc"
    continue
  fi

  mklnk "$base_folder"/Packages/IPNWB  "$user_proc/IPNWB"
  mklnk "$base_folder"/Packages/MIES_Include.ipf  "$user_proc/MIES_Include.ipf"
  mklnk "$base_folder"/Packages/MIES  "$user_proc/MIES"
  mklnk "$base_folder"/Packages/Settings  "$user_proc/Settings"
  mklnk "$base_folder"/Packages/Stimsets  "$user_proc/Stimsets"

  mkdir -p "$user_proc/ITCXOP2"
  mklnk "$base_folder"/Packages/ITCXOP2/tools "$user_proc/ITCXOP2"

  mkdir -p "$xops64"

  if [ "$skipHardwareXOPs" = "0" ]
  then
    mklnk "$base_folder"/XOPs-IP${i}-64bit  "$xops64/IP${i}"
    mklnk "$base_folder"/XOPs-64bit  "$xops64/generic"
  else
    mklnk "$base_folder"/XOPs-64bit/MIESUtils*  "$xops64/MIESUtils"
    mklnk "$base_folder"/XOPs-64bit/JSON*  "$xops64/JSON"
    mklnk "$base_folder"/XOPs-64bit/ZeroMQ*  "$xops64/ZeroMQ"
    mklnk "$base_folder"/XOPs-64bit/TUF*  "$xops64/TUF"
    mklnk "$base_folder"/XOPs-64bit/libzmq*  "$xops64/libzmq"
    mklnk "$base_folder"/XOPs-64bit/mies-nwb2-compound*  "$xops64/mies-nwb2-compound"
  fi

  if [ "$sourceLoc" = "git" ]
  then
    echo "Release: FAKE MIES VERSION" > "$base_folder"/version.txt
  fi

  mklnk "$base_folder"/version.txt "$igor_user_files/version.txt"
done

exit 0

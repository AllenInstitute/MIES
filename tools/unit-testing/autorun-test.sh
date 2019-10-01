#!/bin/bash

# Usage: $0 [-p <name of pxp to run against>] [-v <igor version string>]

StateFile=DO_AUTORUN.txt

touch $StateFile

usage()
{
  echo "Usage: $0 [-p <name of pxp to run against>] [-v <igor version string>]" 1>&2
  echo "       Igor Pro version string: IP_[0-9]+_(32|64)" 1>&2
  exit 1
}

while getopts ":p:v:" o; do
    case "${o}" in
        v)
            igorProVersion=${OPTARG}
            ;;
        p)
            experiment=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${igorProVersion}" ]
then
  # use former default
  igorProVersion="IP_7_64"
fi

if [ -z "${experiment}" ]
then
  # use safe default
  experiment=$(ls *.pxp | head -n1)
fi

igorProPath=$(./get-igor-path.sh ${igorProVersion})

echo "Running experiment $experiment"

case $MSYSTEM in
  MINGW*)
    # we don't want MSYS path conversion, as that would break the /X options,
    # see https://github.com/git-for-windows/build-extra/blob/master/ReleaseNotes.md
    MSYS_NO_PATHCONV=1 "${igorProPath}" /CompErrNoDialog /N /I "$experiment"
    ;;
  *)
    env WINEPREFIX=/home/thomasb/.wine-igor wine "${igorProPath}" /CompErrNoDialog /N /I "$(pwd)/$experiment"
    ;;
esac

rm -f $StateFile

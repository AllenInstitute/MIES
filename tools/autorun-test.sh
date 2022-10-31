#!/bin/bash

# Usage: $0 [-p <name of pxp to run against>] [-v <igor version string>]

# https://stackoverflow.com/a/246128
ScriptDir=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

usage()
{
  echo "Usage: $0 [-p <name of pxp to run against>] [-v <igor version string>]" 1>&2
  echo "       Igor Pro version string: IP_[0-9]+_(32|64)" 1>&2
  exit 1
}

while getopts ":p:t:v:" o; do
    case "${o}" in
        p)
            experiment=${OPTARG}
            ;;
        v)
            igorProVersion=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${experiment}" ]
then
  exit 1
fi

StateFile=$(dirname ${experiment})/DO_AUTORUN.txt
touch $StateFile

if [ -z "${igorProVersion}" ]
then
  exit 1
fi

igorProPath=$(${ScriptDir}/get-igor-path.sh ${igorProVersion})

echo "Running experiment $experiment"

case $MSYSTEM in
  MINGW*)
    # we don't want MSYS path conversion, as that would break the /X options,
    # see https://github.com/git-for-windows/build-extra/blob/master/ReleaseNotes.md
    MSYS_NO_PATHCONV=1 "${igorProPath}" /CompErrNoDialog /N /I "$experiment"
    ret=$?
    ;;
esac

rm -f $StateFile

exit $ret

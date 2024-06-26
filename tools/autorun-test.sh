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

if [ ! -f "${experiment}" ]
then
  echo "The given experiment ${experiment} is not an existing file." 1>&2
  exit 1
fi

if [ -z "${igorProVersion}" ]
then
  echo "The Igor Pro Version is empty." 1>&2
  exit 1
fi

StateFile=$(dirname ${experiment})/DO_AUTORUN.txt
touch $StateFile

igorProPath=$(${ScriptDir}/get-igor-path.sh ${igorProVersion})

echo "##[group]Running experiment $experiment"

# we don't want MSYS path conversion, as that would break the /X options,
# see https://github.com/git-for-windows/build-extra/blob/master/ReleaseNotes.md
MSYS_NO_PATHCONV=1 "${igorProPath}" /UNATTENDED /N /I "$experiment"
ret=$?

echo "##[endgroup]"

echo "Igor returned with status code $ret"

rm -f $StateFile

if [ ! $ret = 0 ]; then
  exit $ret
fi

echo "##[group]Verify JUnit files"
tools/verify-junit-files.sh Packages/tests/**/JU_*.xml
ret=$?
echo "##[endgroup]"

exit $ret

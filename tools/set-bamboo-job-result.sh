#!/bin/bash

# Usage: $0 [-r <0 for success, 1 for failed>]

usage()
{
  echo "Usage: $0 [-r <0 for success, 1 for failed>]" 1>&2
  exit 1
}

while getopts ":r:" o; do
    case "${o}" in
        r)
            result=${OPTARG}
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

cd $top_level/tools

if [ "$result" = "1" ]
then
  cp JU_Failed.xml unit-testing
elif [ "$result" = "0" ]
then
  cp JU_Passed.xml unit-testing
else
  usage
fi

exit 0

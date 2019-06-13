#!/bin/sh

set -e

echo MIES_Include >> input.txt

# test UTF includes as well
if [ "$#" -gt 0 -a "$1" = "all" ]
then

  echo UTF_Main         >> input.txt
  echo UTF_HardwareMain >> input.txt

  # discard first parameter
  shift
fi

echo DEBUGGING_ENABLED >> define.txt
echo EVIL_KITTEN_EATING_MODE >> define.txt

./autorun-test.sh $@

exit 0

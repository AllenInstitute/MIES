#!/bin/sh

set -e

export DISPLAY=:0

echo MIES_Include >> input.txt

# test UTF includes as well
if [ "$#" -gt 0 -a "$1" = "all" ]
then

  echo UTF_Main         >> input.txt
  echo UTF_HardwareMain >> input.txt

fi

echo DEBUGGING_ENABLED >> define.txt
echo EVIL_KITTEN_EATING_MODE >> define.txt

./autorun-test.sh

exit 0

#!/bin/sh

set -e

export DISPLAY=:0

rm -f *.log

runner=autorun-test.sh

if [ -e $runner ]
then
  ./$runner

  grep -q "^[[:space:]]*Test finished with no errors[[:space:]]*$" *.log 2> /dev/null

  exit $?
else
  # required for old release branches without unit testing available
  echo "Could not find $runner, skipping unit tests." > /dev/stderr
  exit 0
fi

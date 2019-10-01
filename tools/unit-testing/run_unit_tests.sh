#!/bin/sh

set -e

export DISPLAY=:0

runner=autorun-test.sh

if [ -e $runner ]
then
  ./$runner $@

  exit 0
else
  # required for old release branches without unit testing available
  echo "Could not find $runner, skipping unit tests." > /dev/stderr
  exit 0
fi

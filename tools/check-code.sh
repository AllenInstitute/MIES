#!/bin/bash

ret=0
opts="--perl-regexp --ignore-case -I -H --full-name --line-number --show-function"

matches=$(git grep $opts "panelTitle" -- '*.ipf')

if [[ -n "$matches" ]]
then
  echo "The panelTitle check failed and found the following occurences:"
  echo "$matches"
  ret=1
fi

exit $ret

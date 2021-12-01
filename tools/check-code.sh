#!/bin/bash

ret=0

matches=$(git grep -hiI "panelTitle" -- :/ :^/tools)

if [[ -n "$matches" ]]
then
  echo "The panelTitle check failed and found the following occurences:"
  echo "$matches"
  ret=1
fi

exit $ret

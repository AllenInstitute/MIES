#!/bin/bash

set -e

nextIssue=$(curl -X GET -sL -H "Accept: application/vnd.github.v3+json" \
https://api.github.com/repos/AllenInstitute/MIES/issues?state=all       \
| jq '[.[] | .number] | max + 1')

nextPR=$(curl -X GET -sL -H "Accept: application/vnd.github.v3+json" \
https://api.github.com/repos/AllenInstitute/MIES/pulls?state=all       \
| jq '[.[] | .number] | max + 1')

if [[  $nextIssue -gt $nextPR ]]
then
  echo $nextIssue
else
  echo $nextPR
fi

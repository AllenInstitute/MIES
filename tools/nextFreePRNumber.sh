#!/bin/bash

set -e

nextIssue=$(curl -X GET -sL -H "Accept: application/vnd.github.v3+json" \
https://api.github.com/repos/AllenInstitute/MIES/issues?state=all       \
| jq '[.[] | .number] | max + 1')

nextPR=$(curl -X GET -sL -H "Accept: application/vnd.github.v3+json" \
https://api.github.com/repos/AllenInstitute/MIES/pulls?state=all       \
| jq '[.[] | .number] | max + 1')

nextFree=$(($nextIssue > $nextPR ? $nextIssue : $nextPR))

# now search the first discussion ID which gives a http 404
# the discussions API is graphQL only and needs authentication
while [ true ]
do
  statusCode=$(curl -o /dev/null -I -L -s -w "%{http_code}" https://github.com/AllenInstitute/MIES/discussions/$nextFree)

  if [ $statusCode -eq 200 ]
  then
    nextFree=$((nextFree + 1))
    continue
  fi

  break
done

echo $nextFree

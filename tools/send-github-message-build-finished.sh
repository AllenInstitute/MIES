#!/bin/bash

git --version > /dev/null
if [ $? -ne 0 ]
then
  echo "Could not find git executable"
  exit 1
fi

top_level=$(git rev-parse --show-toplevel)

if [ -z "$top_level" ]
then
  echo "This is not a git repository"
  exit 1
fi

CREDENTIALS=~/.credentials/github_api_token

if [ ! -f $CREDENTIALS ]
then
  echo "Could not find the file $CREDENTIALS with the Github OAuth token"
  exit 1
fi

AUTH_TOKEN=$(cat $CREDENTIALS)
GITHUB_API=https://api.github.com
REPO=AllenInstitute/MIES
URL=${bamboo_buildResultsUrl}
SHA=${bamboo_repository_revision_number}
GITHUB_STATUS_ENDPOINT=$GITHUB_API/repos/$REPO/statuses/$SHA
CONTEXT=${bamboo_shortJobName}

RESULT_FILES=$(find $top_level/tools/*-testing -iname "JU_*.xml")

if [ -z "$RESULT_FILES" ]
then
  FAILURES=1
else
  FAILURES=$(grep "\(errors\|failures\)=\"[0-9]\+\"" $RESULT_FILES | grep -cv "failures=\"0\" errors=\"0\"")
fi

if [ $FAILURES -eq 0 ]
then
  DESCRIPTION_MSG="passed"
  STATE="success"
else
  DESCRIPTION_MSG="failed"
  STATE="failure"
fi

DESCRIPTION="Build #${bamboo_buildNumber} ${DESCRIPTION_MSG}"
curl -s -L -k -H "Authorization: token ${AUTH_TOKEN}" --request POST --data "{ \"context\": \"${CONTEXT}\", \"state\": \"${STATE}\", \"description\": \"${DESCRIPTION}\", \"target_url\": \"${URL}\"}" ${GITHUB_STATUS_ENDPOINT}

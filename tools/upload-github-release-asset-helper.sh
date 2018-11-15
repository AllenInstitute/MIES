#!/usr/bin/env bash
#
# Author: Stefan Buck
# License: MIT
# https://gist.github.com/stefanbuck/ce788fee19ab6eb0b4447a85fc99f447
#
#
# This script accepts the following parameters:
#
# * owner
# * repo
# * tag
# * filename
# * github_api_token
#
# Script to upload a release asset using the GitHub API v3.
#
# Example:
#
# upload-github-release-asset.sh github_api_token=TOKEN owner=stefanbuck repo=playground tag=v0.1.0 filename=./build.zip filename=./build2.zip
#
# 8/2018: Heavily modified by Thomas Braun

set -e

[ "$TRACE" ] && set -x

function extractValue
{
  release_json=$1
  key=$2

  echo "$release_json" | grep "\"\b${key}\b" | head -n1 | cut -d ":" -f 2 | sed -e 's/,//g'
}

counter=0

# argument parsing
for arg in "$@"
do
  key=$(echo $arg | cut -f1 -d=)
  value=$(echo $arg | cut -f2 -d=)

  case "$key" in
    github_api_token)
      github_api_token=${value}
      ;;
    owner)
      owner=${value}
      ;;
    repo)
      repo=${value}
      ;;
    tag)
      tag=${value}
      ;;
    filename)
      filename=${value}

      if [[ ! -f $filename ]]
      then
        echo "File $filename does not exist"
        exit 1
      fi

      filenames[$counter]=${filename}
      counter=`expr $counter \+ 1`
      ;;
    *)
      echo "Unknown param $key"
      exit 1
      ;;
  esac
done

# Define variables
GH_API="https://api.github.com"
GH_REPO="$GH_API/repos/$owner/$repo"
AUTH="Authorization: token $github_api_token"

if [[ "$tag" == 'LATEST' ]]
then
  GH_TAGS="$GH_REPO/releases/latest"
else
  GH_TAGS="$GH_REPO/releases/tags/$tag"
fi

# Validate token
curl -o /dev/null -sH "$AUTH" $GH_REPO || { echo "Error: Invalid repo, token or network issue!";  exit 1; }

# Read asset tags
response=$(curl -sH "$AUTH" $GH_TAGS)

# Get ID of the release
if echo "$response" | grep -q "\bid\b"
then
  release_id=$(echo "$response" | grep "\bid\b" | head -n1 | grep -oP "([[:digit:]]+)")
else
  echo "Error: Failed to get release id for tag: $tag"
  echo "$response" >&2
  exit 1
fi

# Delete all existing assets
if echo "$response" | grep -q -A1 "releases/assets/"
then
  for asset_id in $(echo "$response" | grep -A1 "releases/assets/" | grep "\bid\b" | grep -oP "([[:digit:]]+)")
  do
    echo "Deleting asset ($asset_id) ..."
    curl -s -X "DELETE" -H "$AUTH" "https://api.github.com/repos/$owner/$repo/releases/assets/$asset_id"
  done
else
  echo "No need to delete assets."
fi

echo "Uploading assets ..."

# Upload assets
for filename in "${filenames[@]}"
do
  GH_ASSET="https://uploads.github.com/repos/$owner/$repo/releases/$release_id/assets?name=$(basename $filename)"

  curl --data-binary @"$filename" -H "$AUTH" -H "Content-Type: application/octet-stream" $GH_ASSET -so /dev/null && echo "Successfully uploaded $filename."
done

echo "Updating release description"

tag_name=$(extractValue "$response" "tag_name")
target_commitish=$(extractValue "$response" "target_commitish")
name=$(extractValue "$response" "name")
draft=$(extractValue "$response" "draft")
prerelease=$(extractValue "$response" "prerelease")

release_description=$(cat <<EOF
{
  "tag_name": ${tag_name},
  "target_commitish": ${target_commitish},
  "name": ${name},
  "body": "Last updated: $(date +"%F %T%z")\n\nThe installer package should work for all users. Only users wishing to manually install the package need the zip file.\n\nSee [here](https://alleninstitute.github.io/MIES/releasenotes.html) for the changelog and [here](https://alleninstitute.github.io/MIES/index.html) for the documentation.",
  "draft":${draft},
  "prerelease": ${prerelease}
}
EOF
)

curl -H "$AUTH" -d "$release_description" "https://api.github.com/repos/$owner/$repo/releases/$release_id" -so /dev/null

#!/bin/bash

# Get top level of git repo
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

pushd "$top_level" >& /dev/null

filter=""
while read -r line; do
    filter="$filter -and -not -path \"./$line/*\""
done < <(git config --file .gitmodules --get-regexp path | awk '{ print $2 }')

echo "[format]" > config.toml
while read -r line; do
    echo "files = \"$line\"" >> config.toml
done < <(bash -c "/usr/bin/find . -name \"*.ipf\" $filter")

popd >& /dev/null

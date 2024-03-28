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

if [ -n "$CI" ]
then
  ipt="./ipt.exe"
else
  ipt="ipt"
fi

echo "[format]" > config.toml
while read -r line; do
    echo "files = \"$line\"" >> config.toml
done < <(git ls-files ':(attr:ipt)')
$ipt --arg-file config.toml format -i

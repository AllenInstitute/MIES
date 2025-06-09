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

echo "[lint]" > config.toml

echo "noreturn-func=FATAL_ERROR|SFH_FATAL_ERROR|FAIL" >> config.toml

while read -r line; do
    echo "files = \"$line\"" >> config.toml
done < <(git ls-files ':(attr:ipt)')

(cd $top_level && $ipt --arg-file config.toml lint -i)

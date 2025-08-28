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

config=$(pwd)/config.toml
trap 'rm -f $config' SIGINT SIGQUIT SIGTSTP EXIT

echo "[lint]" > $config

echo "noreturn-func=FATAL_ERROR|SFH_FATAL_ERROR|FAIL" >> $config

while read -r line; do
    echo "files = \"$line\"" >> $config
done < <(git ls-files --full-name ':(attr:ipt)')

(cd $top_level && $ipt --arg-file $config lint -i)

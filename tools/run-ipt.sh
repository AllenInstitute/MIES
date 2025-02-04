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
while read -r line; do
    echo "files = \"$line\"" >> config.toml
done < <(git ls-files ':(attr:ipt)')

echo "exclude = BugproneMissingSwitchDefaultCase" >> config.toml
echo "exclude = BugproneContradictingOverrideAndFreeFlag" >> config.toml
echo "exclude = CodeStyleDefaultPragmas" >> config.toml
echo "exclude = CodeStyleEndIfComment" >> config.toml
echo "exclude = ReadabilityMissingParenthesis" >> config.toml

(cd $top_level && $ipt --arg-file config.toml lint -i)

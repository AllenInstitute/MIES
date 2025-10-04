#!/usr/bin/env bash

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

case $(uname) in
    Linux)
      IPT=$top_level/tools/ipt
      ;;
    MINGW*)
      IPT=$top_level/tools/ipt.exe
      ;;
    *)
esac

${IPT} "$@"

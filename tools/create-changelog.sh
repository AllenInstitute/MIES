#!/bin/sh

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

if [ -z "$(git tag)" ]
then
  echo "Could not find any tags!"
  echo "This looks like a shallow clone."
  exit 1
fi

git_dir=$(git rev-parse --git-dir)

# %h: abbreviated hash
# %<(N,trunc): cutoff next placeholder if longer than N
# %s: subject
# %w(0,0,10): rewraps next placeholder with 10 indentation
# %b: body (+ means prefix with newline if not empty)
fmt="(%h) %<(80,trunc)%s%w(0,0,10)%+b"
old_tag=$(git describe --tags --abbrev=0 --match "Release_*")

git --git-dir=$git_dir log --submodule=diff --no-merges --pretty="$fmt" $old_tag..HEAD > changelog.txt

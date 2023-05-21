#!/bin/bash

set -e

# Deployment script for our sphinx/doxygen/breathe documentation
#
# Expectations:
# - Called from the MIES repository (full clone)
# - The boundary commit on the gh-pages branch exists. This commit separates
#   the commits we can throw away (old documentation) from the ones we want to keep
#   (setup and stuff).
# - The documentation is present as zip file in the working tree root

push_opts=
# push_opts=--dry-run

if [ -z "$(git tag)" ]
then
  echo "Could not find any tags!"
  echo "This looks like a shallow clone."
  exit 1
fi

top_level=$(git rev-parse --show-toplevel)

if [ -z "$top_level" ]
then
  echo "This is not a git repository"
  exit 1
fi

branch=$(git rev-parse --abbrev-ref HEAD)

case "$branch" in
  main)
    project_version=$(git describe --tags --always --match "Release_*")
    ;;
  release/*)
    version="$(echo "$branch" | grep -Po "(?<=release/).*")"
    project_version=$(git describe --tags --always --match "Release_${version}_*")
    ;;
  *)
    echo "Skipping outdated documentation deployment."
    exit 0
    ;;
esac

tmpdir="$(mktemp -d)"
function cleanup {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

unzip -o mies-docu*.zip
mv ${top_level}/html "$tmpdir/"

git stash || true
git checkout gh-pages
# get the commit hash for the boundary commit
boundary=$(git log --grep="EMPTY_BOUNDARY_COMMIT_FOR_REWRITE" --pretty=format:%H gh-pages)
git reset --hard $boundary
git clean -ffdx

cp -r ${tmpdir}/html/* .

git add -A
git commit --author="MIES Deployment <mies-deploy@linux-mint-box.seattle>" -m "Updating documentation to ${project_version}"
git push ${push_opts} --force-with-lease

exit 0

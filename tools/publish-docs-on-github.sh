#!/bin/bash

set -e

# Deployment script for our sphinx/doxygen/breathe documentation
# Expectations:
# - Called from the MIES repository (full clone)
# - $public_mies_repo exists and its origin remote is the github repository
# - The deployment key is setup correctly for that repository in Github. See also $public_mies_repo/.git/config and ~/.ssh/config
# - The boundary commit on the gh-pages branch exists. This commit separates
#   the commits we can throw away (old documentation) from the ones we want to keep
#   (setup and stuff).
# - The documentation was already successfully built

push_opts=
# push_opts=--dry-run

if [ -z "$(git tag)" ]
then
  echo "Could not find any tags!"
  echo "This looks like a shallow clone."
  exit 1
fi

project_version=$(git describe --tags --always --match "Release_*")
public_mies_repo=~/devel/public-mies-igor

top_level=$(git rev-parse --show-toplevel)

if [ -z "$top_level" ]
then
  echo "This is not a git repository"
  exit 1
fi

if [ ! -d "$public_mies_repo" ]
then
  echo "The folder $public_mies_repo does not exist"
  exit 1
fi

cd $public_mies_repo

git stash || true
git checkout gh-pages
# get the commit hash for the boundary commit
boundary=$(git log --grep="EMPTY_BOUNDARY_COMMIT_FOR_REWRITE" --pretty=format:%H gh-pages)
git reset --hard $boundary
git clean -ffdx

cp -r ${top_level}/Packages/doc/html/* .

git add -A 
git commit --author="MIES Deployment <mies-deploy@linux-mint-box.seattle>" -m "Updating documentation to ${project_version}"
git push ${push_opts} --force-with-lease

exit 0

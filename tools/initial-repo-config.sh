#!/bin/sh

git config --local filter.compress.clean "gzip -3 --no-name --stdout"
git config --local filter.compress.smudge "gzip --decompress --stdout"

# remove Git index
git read-tree --empty

# rescan index
git reset --quiet HEAD -- :/

# do initial smudging
git checkout :/

# fetch submodules
git submodule init
git submodule update --checkout
git submodule foreach "git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'"

# recursive submodule checkout can be done with
# git submodule update --checkout --init --recursive

# set remote URL of submodules to ssh for push/pull
# git remote set-url origin git@github.com:AllenInstitute/IPNWB

# set revision file to ignore for git blame
git config blame.ignoreRevsFile .git-blame-ignore-revs

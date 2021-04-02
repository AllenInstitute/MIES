#!/bin/sh

git config --local filter.compress.clean "gzip -3 --no-name --stdout"
git config --local filter.compress.smudge "gzip --decompress --stdout"

# remove Git index
rm -f .git/index

# rescan index
git reset HEAD -- .

git checkout .

# do initial smudging
git checkout .

# fetch submodules
git submodule init
git submodule update --checkout

# recursive submodule checkout can be done with
# git submodule update --checkout --init --recursive

# set remote URL of submodules to ssh for push/pull
# git remote set-url origin git@github.com:AllenInstitute/IPNWB

# ignore git attributes on foreign submodules
mkdir -p .git/modules/Packages/ITCXOP2/modules/src/SafeInt/info
echo '**/* !whitespace !eol' > .git/modules/Packages/ITCXOP2/modules/src/SafeInt/info/attributes

# set revision file to ignore for git blame
git config blame.ignoreRevsFile .git-blame-ignore-revs

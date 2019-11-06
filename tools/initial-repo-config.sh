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
git submodule init
git submodule update --checkout

# ignore git attributes on foreign submodules
mkdir -p .git/modules/Packages/ZeroMQ-XOP/modules/src/libzmq/info
echo '**/* !whitespace !eol' > .git/modules/Packages/ZeroMQ-XOP/modules/src/libzmq/info/attributes

mkdir -p .git/modules/Packages/ITCXOP2/modules/src/SafeInt/info
echo '**/* !whitespace !eol' > .git/modules/Packages/ITCXOP2/modules/src/SafeInt/info/attributes

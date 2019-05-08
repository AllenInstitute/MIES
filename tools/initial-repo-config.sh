#!/bin/sh

git config --local filter.compress.clean "gzip"
git config --local filter.compress.smudge "gzip -d"

git submodule init
git submodule update --checkout

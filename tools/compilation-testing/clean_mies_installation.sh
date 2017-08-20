#!/bin/sh

# Perform a clean MIES installation on linux
# Copies the procedures to the "User Procedures" folder. This is different from what Readme.md suggests, but we need that for our compilation testing.

set -e

git --version > /dev/null
if [ $? -ne 0 ]
then
  echo "Could not find git executable"
  exit 1
fi

top_level=$(git rev-parse --show-toplevel)

if [ ! -d "$top_level" ]
then
  echo "Could not find git repository"
  exit 1
fi

rm -rf ~/WaveMetrics

user_proc="$HOME/WaveMetrics/Igor Pro 7 User Files/User Procedures"
xops="$HOME/WaveMetrics/Igor Pro 7 User Files/Igor Extensions (64-bit)"

mkdir -p "$user_proc"
mkdir -p "$xops"

rm -rf "$top_level"/Packages/doc/html
cp -r  "$top_level"/Packages/*  "$user_proc"
cp -r  "$top_level"/XOPs-IP7-64bit/*  "$xops"
cp -r  "$top_level"/XOP-tango-IP7-64bit/* "$xops"
rm -f  "$xops"/NIDAQmx64.*

exit 0

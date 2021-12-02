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

cd $top_level/Packages/doc/dot

for i in $(ls *patch-seq*.dot auto-testpulse.dot)
do
  dot -T canon $i -o $i.opt
  dos2unix -q $i.opt
  mv $i.opt $i
done

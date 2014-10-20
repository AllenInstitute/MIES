#!/bin/sh

git diff-index --quiet --cached HEAD
if [ $? -eq 1 ]
then
  echo "Your repository has staged changes, please commit/reset them before continuing."
  exit 1
fi

git diff-files --quiet
if [ $? -eq 1 ]
then
  echo "Your working tree has changed files, please commit/reset them before continuing."
  exit 1
fi

version=$(git describe --always --tags)

echo $version > ../version.txt

cd ..
git archive -o tools/$version.zip HEAD
tools/zip -q tools/$version.zip version.txt
cd tools

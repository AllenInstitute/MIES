#!/bin/bash

top_level=$(git rev-parse --show-toplevel)

cd $top_level

ret=0
opts="--perl-regexp --ignore-case -I -H --full-name --line-number --show-function"
rg_opts="--ignore-case -H --line-number"

matches=$(git grep $opts "panelTitle" -- '*.ipf')

if [[ -n "$matches" ]]
then
  echo "The panelTitle check failed and found the following occurences:"
  echo "$matches"
  ret=1
fi

matches=$(git grep $opts "\b(CHECK|REQUIRE|WARN)\b\(.*(==|<=|>=|<|>|&&|\|\|).*\)" -- '*.ipf')

if [[ -n "$matches" ]]
then
  echo "The test assertion check failed and found the following occurences:"
  echo "$matches"
  ret=1
fi

matches=$(git grep $opts "^ +[^\s*//]" -- '*.ipf')

if [[ -n "$matches" ]]
then
  echo "The line-starts-with-space check failed and found the following occurences:"
  echo "$matches"
  ret=1
fi

# ripgrep checks

files=$(git ls-files '*.ipf' '*.sh' '*.rst' '*.dot' '*.md' ':!:**/releasenotes_template.rst')

# from https://til.simonwillison.net/bash/finding-bom-csv-files-with-ripgrep
matches=$(rg ${rg_opts} --multiline --encoding none '^(?-u:\xEF\xBB\xBF)' ${files})

if [[ -n "$matches" ]]
then
  echo "The Byte-Order-marker check failed and found the following occurences:"
  echo "$matches"
  ret=1
fi

matches=$(rg ${rg_opts} --multiline '\n\n\n' ${files})

if [[ -n "$matches" ]]
then
  echo "The duplicated newlines check failed and found the following occurences:"
  echo "$matches"
  ret=1
fi

matches=$(rg ${rg_opts} '[[:space:]]+$' ${files})

if [[ -n "$matches" ]]
then
  echo "The trailing whitespace check failed and found the following occurences:"
  echo "$matches"
  ret=1
fi

exit $ret

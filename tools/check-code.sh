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

matches=$(git grep $opts "^(Str)?Constant\b" '*/MIES_*.ipf' '*/UTF_*.ipf' ':^*/MIES_Constants.ipf' ':^*/MIES_ConversionConstants.ipf' ':^*/UTF_HardwareMain.ipf')

if [[ -n "$matches" ]]
then
  echo "Global constants are only allowed in MIES_Constants.ipf, MIES_ConversionConstants.ipf and UTF_HardwareMain.ipf:"
  echo "$matches"
  ret=1
fi

matches=$(git grep $opts "^Structure\b" '*/MIES_*.ipf' '*/UTF_*.ipf' ':^*/MIES_Structures.ipf' ':^*/UTF_HardwareMain.ipf')

if [[ -n "$matches" ]]
then
  echo "Global structures are only allowed in MIES_Structures.ipf and UTF_HardwareMain.ipf:"
  echo "$matches"
  ret=1
fi

# 1: all types of 10, 100 and 1e3, 1e-6, 1E09 etc. but not tol = 1e3 or 10^. Has to be prefixed with * or / or *=
# 2: not in constants
# 3: not in test assertions
# 4: ignored in comments
# 5: respects NOLINT
matches=$(git grep $opts                                                                                                              \
                   -e '(?<!tol=)(?<!tol =)(?<!tol = )(?<!tol= )(\*|/)[[:space:]]*(=)?[[:space:]]*(10+(?!\^)|1e(-|\+)?[[:digit:]]+)\b' \
                   --and --not -e '^[[:space:]]*(Str)?Constant'                                                                       \
                   --and --not -e '^[[:space:]]*(REQUIRE|CHECK|WARN)_([a-z]+)_([a-z]+)\('                                             \
                   --and --not -e '^[[:space:]]*//'                                                                                   \
                   --and --not -e '//[[:space:]]*NOLINT$'                                                                             \
                  '*/MIES_*.ipf' '*/UTF_*.ipf' ':^*/MIES_Pictures.ipf')

if [[ -n "$matches" ]]
then
  echo "Literal decimal multiplier check failed (use \`// NOLINT\` to suppress if appropriate):"
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

matches=$(rg ${rg_opts} --multiline '\n\n(\n|\z)' ${files})

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

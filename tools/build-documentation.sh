#!/bin/bash
# vim: set ts=2 sw=2 tw=0 et :

top_level=$(git rev-parse --show-toplevel)
branch=$(git rev-parse --abbrev-ref HEAD)
version=$(git describe --always --tags --match "Release_*")

function Passed {
  cp "$top_level/tools/JU_Passed.xml" "$top_level/tools/unit-testing/"
  exit 0
}

# logging function inspired by https://stackoverflow.com/a/33597663/7809404
# set verbose level to warning
declare -A LOG_LEVELS LOG_COLORS
LOG_LEVELS=([0]="emerg" [1]="alert" [2]="crit " [3]="err" [4]="warning" [5]="notice" [6]="info" [7]="debug")
LOG_COLORS=([0]="91m"   [1]="91m"   [2]="91m"  [3]="91m" [4]="93m"     [5]="96m"    [6]="92m"  [7]="90m"  )
VERBOSE=7

function .log () {
  local LEVEL=${1}
  shift
  if [ ${VERBOSE} -ge ${LEVEL} ]; then
    while read line; do
      python3 -c "print('\033[${LOG_COLORS[$LEVEL]}[${LOG_LEVELS[$LEVEL]}]\033[0m ' + '$line')"
    done <<< "$@"
  fi

  if [ 4 -ge ${LEVEL} ]; then
    .log 6 "Error building the documentation"
    .log 6 "================================"
    cp "$top_level/tools/JU_Failed.xml" "$top_level/tools/unit-testing/"
    exit 1
  fi
}

case $(uname) in
    Linux)
      ZIP_EXE=zip
      ;;
    *)
      ZIP_EXE="$top_level/tools/zip.exe"
      ;;
esac

echo
.log 6 "Building The Documentation"
.log 6 "=========================="

cd "$top_level/Packages/doc"

echo
.log 6 "Analyzing Doxygen Comments"
.log 6 "--------------------------"

if ! command -v doxygen > /dev/null; then .log 2 "[doxygen] doxygen not found."; fi
.log 7 "[doxygen] $(doxygen --version)"
if ! (cat Doxyfile; echo "HAVE_DOT = NO"; echo "GENERATE_HTML = NO") | doxygen -
then
  .log 3 "[doxygen] failed."
fi

.log 6 "[dot] Converting dot Files To svg"
if ! command -v dot > /dev/null; then .log 2 "[dot] dot/graphviz not found."; fi
.log 7 "[dot] $(dot -V)"

for i in $(ls *.dot)
do
	dot -Tsvg -O "$i"
done

cp "$top_level/Packages/IPNWB/Readme.rst" "$top_level/Packages/doc/IPNWB.rst"
cp "$top_level/Packages/ZeroMQ/Readme.rst" "$top_level/Packages/doc/ZeroMQ-XOP-Readme.rst"

.log 6 "[breathe] Converting doxygen xml To rst"
if ! command -v breathe-apidoc > /dev/null; then .log 2 "[breathe] breathe-apidoc not found."; fi
.log 7 "[breathe] $(breathe-apidoc --version)"
breathe-apidoc -f -o . xml

# Add labels to each group and each file
# can be referenced via :ref:`Group LabnotebookQueryFunctions`
# or :ref:`File MIES_Utilities.ipf`

for i in `ls group/group_*.rst`
do
  name=$(sed -e '$!d' -e 's/.*doxygengroup:: \(.*\)$/\1/' $i)
  sed -i "1s/^/.. _Group ${name}:\n\n/" $i
done

for i in `ls file/*.rst`
do
  name=$(sed -e '$!d' -e 's/.*doxygenfile:: \(.*\)$/\1/' $i)
  sed -i "1s/^/.. _File ${name}:\n\n/" $i
done

echo
.log 6 "Build Sphinx Documentation"
.log 6 "--------------------------"

if ! command -v sphinx-build > /dev/null; then .log 2 "[sphinx] sphinx-build not found."; fi
.log 7 "[sphinx] $(sphinx-build --version)"
rm -f sphinx-output.log
sphinx-build -w sphinx-output.log . html
if [ -s "sphinx-output.log" ]
then
  .log 5 "[sphinx] $(python3 --version)"
  .log 5 "[sphinx] $(pip3 list sphinx)"
fi

.log 6 "[sphinx] zipping the results"
${ZIP_EXE} --version

rm -f mies-docu*.zip
"$ZIP_EXE" -qr0 mies-docu-$version.zip html

Passed

# handle cases where we are called with plain sh
# which does not know about functions
exit 1

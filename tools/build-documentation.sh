#!/bin/bash

top_level=$(git rev-parse --show-toplevel)
branch=$(git rev-parse --abbrev-ref HEAD)
version=$(git describe --always --tags --match "Release_*")

function Passed {
  cp "$top_level/tools/JU_Passed.xml" "$top_level/tools/unit-testing/"
  exit 0
}

function Failed {
  cp "$top_level/tools/JU_Failed.xml" "$top_level/tools/unit-testing/"
  exit 1
}

case $(uname) in
    Linux)
      ;;
    *)
      # install the correct packages
      # this is more convenient for users
      pip install -r $top_level/tools/docker/requirements.txt > /dev/null || Failed
      ;;
esac

case $(uname) in
    Linux)
      ZIP_EXE=zip
      ;;
    *)
      ZIP_EXE="$top_level/tools/zip.exe"
      ;;
esac

echo "Start building the documentation"

cd "$top_level/Packages/doc"

output=$( (cat Doxyfile ; echo "HAVE_DOT = NO" ; echo "GENERATE_HTML = NO") | doxygen - 2>&1  >/dev/null | grep -v "warning: ignoring unsupported tag" )

if [ ! -z  "$output" ]
then
  echo "Errors building the documentation" 1>&2
  echo "Doxygen says: "                    1>&2
  echo "$output"                           1>&2
  Failed
fi

if hash dot 2>/dev/null; then
  echo "Start converting dot files to svg"

  cd dot

  for i in $(ls *.dot)
  do
    output=$(basename "$i" .dot)
    dot -Tsvg -o "${output}.svg" "$i"
  done

  cd ..

else
  echo "Errors building the documentation" 1>&2
  echo "dot/graphviz could not be found"   1>&2
  Failed
fi

ln -s "${top_level}/Packages/IPNWB" "${top_level}/Packages/doc/"
rm -rf "${top_level}/Packages/doc/IPNWB/ndx-MIES"
trap "rm -rf ${top_level}/Packages/doc/IPNWB" EXIT

# IPNWB script has dependencies. Disabling it for CI.
#
# cd "${top_level}/Packages/IPNWB"
# bash "${top_level}/Packages/IPNWB/update_doc.sh"
# cd "${top_level}/Packages/doc" # submodule rev-parse

if hash breathe-apidoc 2>/dev/null; then
  echo "Start breathe-apidoc"

  breathe-apidoc -f -o . xml

else
  echo "Errors building the documentation" 1>&2
  echo "breathe-apidoc could not be found" 1>&2
  Failed
fi

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

# create rst substitutions for up-to-date IP nightly links
grep "IgorPro[0-9]Nightly" $top_level/Packages/MIES_Include.ipf \
  | sed -e "s/^\/\/ //"                                         \
  > $top_level/Packages/doc/installation_subst.txt

if hash sphinx-build 2>/dev/null; then
  echo "Start sphinx-build"

  rm -f sphinx-output.log

  sphinx-build -q -w sphinx-output.log . html

  sed -i -e '/WARNING: Duplicate C++ declaration./d' sphinx-output.log
  sed -i -e '/^Declaration is/d' sphinx-output.log

  if [ -s "sphinx-output.log" ]
  then
    echo "Errors building the documentation" 1>&2
    echo "sphinx-build says: "               1>&2
    cat sphinx-output.log                    1>&2
    Failed
  fi

else
  echo "Errors building the documentation" 1>&2
  echo "sphinx-build could not be found"   1>&2
  Failed
fi

echo "Start zipping the results"
rm -f mies-docu*.zip
"$ZIP_EXE" -qr0 mies-docu-$version.zip html
"$ZIP_EXE" -qd mies-docu-$version.zip "html/.doctrees/*" > /dev/null

Passed

# handle cases where we are called with plain sh
# which does not know about functions
exit 1

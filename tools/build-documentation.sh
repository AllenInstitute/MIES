#!/bin/bash

top_level=$(git rev-parse --show-toplevel)
branch=$(git rev-parse --abbrev-ref HEAD)
version=$(git describe --always --tags --match "Release_*")

case $(uname) in
    Linux)
      ;;
    *)
      # install the correct packages
      # this is more convenient for users
      pip install -r $top_level/tools/documentation/requirements.txt > /dev/null || exit 1
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

git clean -fdx xml struct group file namespace _images html

output=$( (cat Doxyfile ; echo "HAVE_DOT = NO" ; echo "GENERATE_HTML = NO") | doxygen - 2>&1  >/dev/null | grep -v "warning: ignoring unsupported tag" )

if [ ! -z  "$output" ]
then
  echo "Errors building the documentation" 1>&2
  echo "Doxygen says: "                    1>&2
  echo "$output"                           1>&2
  exit 1
fi

if hash dot 2>/dev/null; then
  echo "Start converting dot files to svg"

  cd dot

  for i in $(ls *.dot)
  do
    output=$(basename "$i" .dot)
    dot -Tsvg -o "${output}.svg" "$i"
  done

  cp async-qc-channels.svg ../_static/images

  cd ..

else
  echo "Errors building the documentation" 1>&2
  echo "dot/graphviz could not be found, see https://graphviz.org/download/#windows for Windows installer packages."   1>&2
  exit 1
fi

cd "$top_level/Packages/MIES"

echo "Start creating documentation CSV files"

git clean -fx ../doc/csv/*.csv

# The Igor Text file looks like
# ...
# BEGIN
#   "blah"  "blubb \" droepf \"\r numpf"
# END
# ...
#
# the sed calls extracts the correct block, remove the leading tab, and translates \" to "" and \\r to \n.
for i in $(ls *_description.itx analysis_function_parameters.itx analysis_function_abrev_legend.itx)
do
  output=../doc/csv/$(basename "$i" .itx).csv
  begin=$(grep -n "^BEGIN$" $i | cut -f 1 -d ":")
  end=$(grep -n "^END$" $i | cut -f 1 -d ":")
  sed -n "$((${begin} + 1)),$((${end} - 1))p" $i | sed -e 's/^\t//' -e 's/\\"/""/g' -e 's/\\r/\n/g' >> ${output}
done

cd "$top_level/Packages/doc"

ln -s "${top_level}/Packages/IPNWB" "${top_level}/Packages/doc/"
rm -rf "${top_level}/Packages/doc/IPNWB/ndx-MIES"
trap "rm -rf ${top_level}/Packages/doc/IPNWB" EXIT

# workaround https://github.com/sphinx-contrib/images/pull/31
mkdir _video_thumbnail

if hash breathe-apidoc 2>/dev/null; then
  echo "Start breathe-apidoc"

  breathe-apidoc -f -o . xml

else
  echo "Errors building the documentation" 1>&2
  echo "breathe-apidoc could not be found" 1>&2
  exit 1
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
grep -P "IgorPro[0-9]+(Windows|MacOSX)Nightly" $top_level/Packages/MIES_Include.ipf \
  | sed -e "s/^\/\/ //"                                                             \
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
    exit 1
  fi

else
  echo "Errors building the documentation" 1>&2
  echo "sphinx-build could not be found"   1>&2
  exit 1
fi

echo "Start zipping the results"
rm -f mies-docu*.zip
"$ZIP_EXE" -qr0 mies-docu-$version.zip html
"$ZIP_EXE" -qd mies-docu-$version.zip "html/.doctrees/*" > /dev/null

exit 0

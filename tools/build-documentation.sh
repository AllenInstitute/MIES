#!/bin/sh

top_level=$(git rev-parse --show-toplevel)
branch=$(git rev-parse --abbrev-ref HEAD)
version=$(git describe --always --tags)

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
  exit 1
fi

if hash pandoc 2>/dev/null; then
  echo "Start converting markdown files to rst"

  pandoc -f markdown_strict+fenced_code_blocks "$top_level/README.md" -o readme.rst
  pandoc -f markdown_strict+fenced_code_blocks "$top_level/ReportingBugs.md" -o reportingbugs.rst
  pandoc -f markdown_strict+fenced_code_blocks "$top_level/ManualInstallation.md" -o manualinstallation.rst

else
  echo "Errors building the documentation" 1>&2
  echo "pandoc could not be found"         1>&2
  exit 1
fi

cp "$top_level/Packages/IPNWB/Readme.rst" "$top_level/Packages/doc/IPNWB.rst"
cp "$top_level/Packages/ZeroMQ/Readme.rst" "$top_level/Packages/doc/ZeroMQ-XOP-Readme.rst"

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

if hash sphinx-build 2>/dev/null; then
  echo "Start sphinx-build"

  rm -f sphinx-output.log

  sphinx-build -q -w sphinx-output.log . html

  sed -i -e '/WARNING: Duplicate declaration./d' sphinx-output.log

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

exit 0

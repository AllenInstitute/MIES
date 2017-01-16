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

output=$( (cat Doxyfile ; echo "HAVE_DOT = NO" ; echo "GENERATE_HTML = NO") | doxygen - 2>&1 >/dev/null)

if [ ! -z  "$output" ]
then
  echo "Errors building the documentation" 1>&2
  echo "Doxygen says: "                    1>&2
  echo "$output"                           1>&2
  exit 1
fi

if hash pandoc 2>/dev/null; then
  echo "Start converting markdown files to rst"

  pandoc -f markdown_strict "$top_level/README.md" -o readme.rst
  pandoc -f markdown_strict "$top_level/ReportingBugs.md" -o reportingbugs.rst

else
  echo "Errors building the documentation" 1>&2
  echo "pandoc could not be found"         1>&2
  exit 1
fi

if hash breathe-apidoc 2>/dev/null; then
  echo "Start breathe-apidoc"

  breathe-apidoc -o . xml

else
  echo "Errors building the documentation" 1>&2
  echo "breathe-apidoc could not be found" 1>&2
  exit 1
fi

if hash sphinx-build 2>/dev/null; then
  echo "Start sphinx-build"

  sphinx-build . html

else
  echo "Errors building the documentation" 1>&2
  echo "sphinx-build could not be found"   1>&2
  exit 1
fi

echo "Start zipping the results"
rm -f mies-docu*.zip
"$ZIP_EXE" -qr0 mies-docu-$version.zip html

exit 0

#!/bin/sh

top_level=$(git rev-parse --show-toplevel)
branch=$(git rev-parse --abbrev-ref HEAD)
version=$(git describe --always --tags)

# Doxygen has real issues with quoting and filter patterns.
# The Doxyfile version in the repository works only with Windows
case $(uname) in
    Linux)
      FILTER_PATTERNS='FILTER_PATTERNS = "*.ipf=\"gawk -f doxygen-filter-ipf.awk\""'
      ZIP_EXE=zip
      ;;
    *)
      FILTER_PATTERNS=
      ZIP_EXE="$top_level/tools/zip.exe"
      ;;
esac

echo "Start building the documentation"

cd "$top_level/Packages/doc"

output=$( (cat Doxyfile; echo "PROJECT_NUMBER = \"($branch) $version\""; echo $FILTER_PATTERNS ) | doxygen - 2>&1 >/dev/null)

if [ ! -z  "$output" ]
then
  echo "Errors building the documentation" 1>&2
  echo "Doxygen says: "                    1>&2
  echo "$output"                           1>&2
  exit 1
fi

if hash mogrify 2>/dev/null; then
  echo "Start shrinking the PNGs"

  if hash parallel 2>/dev/null; then
    find html -iname "*.png" | parallel mogrify -quality 0 +dither -colors 32 {}
  else
    mogrify -quality 0 +dither -colors 32 html/*png
  fi
fi

echo "Start zipping the results"
rm -f mies-docu*.zip
"$ZIP_EXE" -qr0 mies-docu-$version.zip html

exit 0

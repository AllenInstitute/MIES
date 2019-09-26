#!/bin/bash

# Get top level of git repo
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

if ! hash sed 2>/dev/null; then
  echo "'sed' is not installed but required."
  exit
fi

# Get zip executable
case $MSYSTEM in
  MINGW*)
    export unzip_exe=$top_level/tools/unzip.exe;;
  *)
    export unzip_exe=unzip;;
esac

cd $top_level
./tools/create-release.sh
zipfile=$(ls Release_*.zip)

cd tools
rm -f installer/*.inc installer/MIES-Release*.exe

#Include file name, must be undecorated file names
#The first name of NSISDEFINCS is fixed to "setincnames.inc"
NSISDEFINCS="setincnames.inc"
NSISOUTFILE="outfile.inc"
NSISREQUEST="requestLevel.inc"
NSISVERSION="version.inc"
NSISINSTFILELIST="filelist.inc"
NSISINSTDIRLIST="dirlist.inc"
NSISUNINSTFILELIST="uninstalllist.inc"
NSISUNINSTDIRLIST="uninstalldirlist.inc"
echo "!define NSISOUTFILE \"$NSISOUTFILE\"" > installer/$NSISDEFINCS
echo "!define NSISREQUEST \"$NSISREQUEST\"" >> installer/$NSISDEFINCS
echo "!define NSISVERSION \"$NSISVERSION\"" >> installer/$NSISDEFINCS
echo "!define NSISINSTFILELIST \"$NSISINSTFILELIST\"" >> installer/$NSISDEFINCS
echo "!define NSISINSTDIRLIST \"$NSISINSTDIRLIST\"" >> installer/$NSISDEFINCS
echo "!define NSISUNINSTFILELIST \"$NSISUNINSTFILELIST\"" >> installer/$NSISDEFINCS
echo "!define NSISUNINSTDIRLIST \"$NSISUNINSTDIRLIST\"" >> installer/$NSISDEFINCS

# Create include to set installer file name
echo "$zipfile" > installer/$NSISOUTFILE
sed -i 's/.zip/.exe/;s/.*/outFile \"MIES-&\"/' installer/$NSISOUTFILE

if [ "$#" -eq 0 ]
then
  echo "RequestExecutionLevel admin" > installer/$NSISREQUEST
else
  echo "RequestExecutionLevel user" > installer/$NSISREQUEST
  sed -i 's/\.exe/-cis.exe/' installer/$NSISOUTFILE
fi

# --- Extract Source Files ---
tmpdir=$(mktemp --tmpdir=. -d)
"$unzip_exe" -q -o ../$zipfile -d$tmpdir

# --- Extract Version Information ---
# Create brief information text for first installer page
# note: first installer page is currently removed
#read -r VERSION<$tmpdir/version.txt
#echo "This installs MIES $VERSION" > installer/license.txt

# Extract version information from the string in the first line of version.txt
# These must be integer numbers
VERSIONMAJOR=$(sed -r '1!d;s/^[^0-9]*([0-9]+).*/\1/' $tmpdir/version.txt)
VERSIONMINOR=$(sed -r '1!d;s/^[^0-9]*[0-9]+[.]([0-9]+).*/\1/' $tmpdir/version.txt)
VERSIONMINOR2=$(sed -r '1!d;s/^[^0-9]*[0-9]+[.][0-9]+[_][0-9]+[-]([0-9]+).*/\1/' $tmpdir/version.txt)
# Creates include file for nsis with defines for version
echo "!define PACKAGEVERSION \"$VERSION\"" > installer/$NSISVERSION
echo "!define VERSIONMAJOR "$VERSIONMAJOR >> installer/$NSISVERSION
echo "!define VERSIONMINOR "$VERSIONMINOR >> installer/$NSISVERSION
echo "!define VERSIONBUILD "$VERSIONMINOR2 >> installer/$NSISVERSION
echo "Extracted version: "$VERSIONMAJOR"."$VERSIONMINOR"."$VERSIONMINOR2

# --- List Generation ---
# Generate file list and dir list for installer and clone it for uninstaller
# The no wildcard approach touches only own files, all other files will be preserved on uninstallation
# As the lists are cloned the install and uninstall is forced to be symmetric
cd $tmpdir
find -type f > ../installer/$NSISINSTFILELIST
cp ../installer/$NSISINSTFILELIST ../installer/$NSISUNINSTFILELIST
find -type d > ../installer/$NSISINSTDIRLIST
cp ../installer/$NSISINSTDIRLIST ../installer/$NSISUNINSTDIRLIST

# Get undecorated source directory of installation files
tmpfile=$(mktemp --tmpdir=.)
echo $tmpdir>$tmpfile
sed -i 's/^..//' $tmpfile
read -r tmpdir<$tmpfile
rm -f $tmpfile

# --- List Code Generation ---
# Generate nsis script code for installation files
sed -i 's/.\///;s/\//\\/g;s/.*/File \"\/oname=&\" \"..\\'"$tmpdir"'\\&\"/' ../installer/$NSISINSTFILELIST
# Generate nsis script code for uninstallation files
sed -i 's/.\///;s/\//\\/g;s/.*/Delete \"\$INSTDIR\\&\"/' ../installer/$NSISUNINSTFILELIST
# Generate nsis script code for installation dir creation, must be in tree order with upmost branches first
# This is guaranteed by the list created from find
sed -i '1d' ../installer/$NSISINSTDIRLIST
sed -i 's/.\///;s/\//\\/g;s/.*/CreateDirectory \"\$INSTDIR\\&\"/' ../installer/$NSISINSTDIRLIST
# Generate nsis script code for uninstallation dir removal, must be in tree order with bottommost branches first
# This is guaranteed by the inverted list created from find
sed -i '1d' ../installer/$NSISUNINSTDIRLIST
sed -i '1!G;h;$!d' ../installer/$NSISUNINSTDIRLIST
sed -i 's/.\///;s/\//\\/g;s/.*/rmDir \"\$INSTDIR\\&\"/' ../installer/$NSISUNINSTDIRLIST
# Run makensis to create installer
cd ../installer
if hash wine 2>/dev/null; then
  wine nsis/makensis installer.nsi
else
  nsis/makensis installer.nsi
fi
cd ..
rm -rf $tmpdir

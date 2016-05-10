#!/bin/sh

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

if [ -z "$(git tag)" ]
then
  echo "Could not find any tags!"
  echo "This looks like a shallow clone."
  exit 1
fi

version=$(git describe --always --tags)
git_dir=$(git rev-parse --git-dir)

case $MSYSTEM in
  MINGW*)
    zip_exe=$top_level/tools/zip.exe;;
  *)
    zip_exe=zip;;
esac

echo "Removing old release packages"
rm -f Release_*zip

git --git-dir=$git_dir archive -o $version.zip HEAD

version_file=$top_level/version.txt
echo $version > "$version_file"
"$zip_exe" -qju $version.zip "$version_file"

# git seems to be buggy on honouring export-ignore attributes on shallow clones
# (bamboo does them by default so we delete the unwanted folders manually here
"$zip_exe" -qd $version.zip "Packages/doc/*"  > /dev/null
"$zip_exe" -qd $version.zip "Packages/ITC/*" > /dev/null
"$zip_exe" -qd $version.zip "Packages/Testing-MIES/*" > /dev/null
"$zip_exe" -qd $version.zip "Packages/unit-testing/*" > /dev/null
"$zip_exe" -qd $version.zip "Packages/Arduino/*.zip" > /dev/null
"$zip_exe" -qd $version.zip "Packages/Arduino/*.exe" > /dev/null
"$zip_exe" -qd $version.zip "tools/*" > /dev/null
"$zip_exe" -qd $version.zip "Guidelines/*" > /dev/null
"$zip_exe" -qd $version.zip "XOPs/NIDAQmx.XOP" > /dev/null
"$zip_exe" -qd $version.zip "XOPs-IP7/NIDAQmx.XOP" > /dev/null

exit 0

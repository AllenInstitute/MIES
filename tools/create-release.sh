#!/bin/bash

function finish
{
  cd "$oldcwd"
}

trap finish exit

oldcwd=$(pwd)

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

cd $top_level

if [ -z "$(git tag)" ]
then
  echo "Could not find any tags!"
  echo "This looks like a shallow clone."
  exit 1
fi

git submodule update --checkout --force > /dev/null
if [ $? -ne 0 ]
then
  echo "Error updating submodules"
  exit 1
fi

git_dir=$(git rev-parse --git-dir)
superproject_version=$(git --git-dir=$git_dir describe --tags --always)
submodule_status=$(git --git-dir=$git_dir submodule status)
date_of_version=$(git --git-dir=$git_dir log -1 --pretty=format:%cI)
output_file=${superproject_version}.zip

full_version="${superproject_version}
Date and time of last commit: ${date_of_version}
Submodule status:
${submodule_status}"

case $MSYSTEM in
  MINGW*)
    export zip_exe=$top_level/tools/zip.exe;;
  *)
    export zip_exe=zip;;
esac

echo "Removing old release packages"
rm -f Release_*zip

git --git-dir=$git_dir archive -o $output_file HEAD

# no support for submodules yet so we have to do that ourselves
# See also https://stackoverflow.com/a/46551763/4859183
git --git-dir=$git_dir submodule --quiet foreach "cd \$toplevel; \$zip_exe -qru \$toplevel/$output_file \$path"
# delete .git files from submodules
# but these are only present on linux and not on windows ...
git --git-dir=$git_dir submodule --quiet foreach "cd \$toplevel; \$zip_exe -qd \$toplevel/$output_file \$path/.git || :" > /dev/null
/bin/echo -e "$full_version" | $zip_exe -qu $output_file -z

version_file=$top_level/version.txt
/bin/echo -e "$full_version" > "$version_file"
"$zip_exe" -qju $output_file "$version_file"

# delete unwanted folders from submodules
# everything else is handled in .gitattributes using export-ignore
"$zip_exe" -qd $output_file "Packages/ITCXOP2/*" > /dev/null
"$zip_exe" -qd $output_file "Packages/unit-testing/*" > /dev/null
"$zip_exe" -qd $output_file "Packages/ZeroMQ/src/*" > /dev/null
"$zip_exe" -qd $output_file "Packages/ZeroMQ/tests/*" > /dev/null
"$zip_exe" -qd $output_file "Packages/ZeroMQ/output/*" > /dev/null
"$zip_exe" -qd $output_file "Packages/ZeroMQ/help/*" > /dev/null
"$zip_exe" -qd $output_file "Packages/ZeroMQ/examples/*" > /dev/null
"$zip_exe" -qd $output_file "Packages/ZeroMQ/xop-stub-generator/*" > /dev/null
"$zip_exe" -qd $output_file "Packages/doc/*" > /dev/null

exit 0

#!/bin/sh

set -e

# Installation:
# - sudo cp tools/depoly_documentation.sh /usr/local/bin/mies_deploy_documentation.sh
# - sudo chown root:root /usr/local/bin/mies_deploy_documentation.sh
# - sudo chown 744 /usr/local/bin/mies_deploy_documentation.sh
# - Make the script executable as root by the bamboo user, e.g. add the following entry
#   with "sudo visudo":
#   bambooUser ALL=(root) NOPASSWD: /usr/local/bin/mies_deploy_documentation.sh
# - Test from inside a mies git repository with "sudo mies_deploy_documentation.sh"

# The requirement for local installation is done for safety reasons, as the
# solution that a script from the git repository is directly executed with
# root privileges is really insecure.

top_level=$(git rev-parse --show-toplevel)
branch=$(git rev-parse --abbrev-ref HEAD)

www_root=/var/www/html

if [ "$(whoami)" != "root" ]
then
	echo "Script has to be executed as root"
	exit 1
fi

case "$branch" in
	master)
		target_dir=${www_root}/master
		;;
	release/*)
		target_dir=${www_root}/release
		;;
	*)
		target_dir=${www_root}/unknown
		;;
esac

source_dir="${top_level}/Packages/doc/html"

if [ ! -d "$source_dir" ]
then
	echo "The source directory $source_dir of the html doxygen documentation could not be found."
	exit 1
fi

echo "Deploying documentation to $target_dir from branch $branch"

rm -rf "$target_dir"

cp -r "$source_dir" "$target_dir"

# Tighten access rights on documentation files
chown -R www-data:www-data "$target_dir"
chmod -R go-rwx "$target_dir"
find "$target_dir" -not -type d -print0 | xargs -0 chmod a-x

exit 0

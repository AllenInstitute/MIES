#!/bin/bash
#
# This scripts injects a function named `DEBUG_STOREFUNCTION()` into a Igor Pro
# Procedure directly after the declaration of variables.
#
# The script can be used to count the calls to functions during code execution.
# Its result is similar to code coverage statistics for Igor Pro.
#

GIT_TOPLEVEL=$(git rev-parse --show-toplevel)
FILES="${GIT_TOPLEVEL}/Packages/IPNWB/IPNWB_*.ipf ${GIT_TOPLEVEL}/Packages/MIES/MIES_*.ipf"

# confirm
echo "$(ls -l $FILES | wc -l) affected files: $FILES"
read -p "execute script [y/N]" -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
	[[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi
echo

# inject
# Note: DEBUG_STOREFUNCTION is not threadsafe
perl -0777 -i -pe 's/(\n(?:(?:static)\s+)?Function(?:\/[A-Z]+)?\s(?!DEBUG_STOREFUNCTION)[^\n]*(?:\n+\s*(?:(?:variable|string|STRUCT|DFREF|WAVE|FUNCREF)[&]?(?:\/[A-Z]+)*\s+[^\n]+|$))*)/\1\n\n\tDEBUG_STOREFUNCTION()\/\/PERLSCRIPT\n/gis' $FILES

# count
echo "DEBUG_STOREFUNCTION() injected into $(grep 'DEBUG_STOREFUNCTION()//PERLSCRIPT' $FILES | wc -l) functions"

# undo
read -p "Press [Enter] to undo injection"
perl -0777 -i -pe 's/\n\n\tDEBUG_STOREFUNCTION\(\)\/\/PERLSCRIPT\n//gis' $FILES

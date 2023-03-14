#!/bin/bash

# TODO remove when moving to github actions

set -e

# https://stackoverflow.com/a/246128
ScriptDir=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

${ScriptDir}/autorun-test.sh $@

exit 0

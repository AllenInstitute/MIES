#!/bin/bash

set -e

function usage ()
{
    echo "Usage: $0 [-s <source dir>] [-d <cobertura dir>] [-h <history dir>] [-o <output dir>] [-l <license>]" 1>&2
    exit 1
}

source="$(pwd)"
directory="$(pwd)"
history="$(pwd)/history"
output="$(date -Id)"

while getopts ":s:d:h:o:l:" key; do
    case "${key}" in
        s)
            source="${OPTARG}"
            ;;
        d)
            directory="${OPTARG}"
            ;;
        h)
            history="${OPTARG}"
            ;;
        o)
            output="${OPTARG}"
            ;;
        l)
            license=" \"-license:${OPTARG}\""
            ;;
        *)
            usage
            ;;
    esac
done

if [ ! -d "$directory" ]; then
    echo "Cobertura directory $directory not found" 1>&2
    usage
fi

if [ ! -d "$source" ]; then
    echo "Source directory $source not found" 1>&2
    usage
fi

mkdir -p "$history"
mkdir -p "$output"

directory="$(realpath "$directory")"
source="$(realpath "$source")"
history="$(realpath "$history")"
output="$(realpath "$output")"

# checks for correct installation
if [ ! $(docker -v | grep -c -w version) -eq 1 ]; then
	echo "docker not found."
	exit 1
fi
if [ ! $(groups | grep -c -w docker) -eq 1 ]; then
	echo "add current user $(whoami) to docker group!"
	exit 1
fi

git --version > /dev/null
if [ $? -ne 0 ]
then
  echo "Could not find git executable"
  exit 1
fi

top_level=$(git rev-parse --show-toplevel)

# fix paths
echo "##[group]Fix source paths"
chmod -R +rw "$directory"
find "$directory" -type f -name "Cobertura_*.xml" -print0 | \
    xargs -0 \
        sed -E -i 's@(<source>)C:.*/MIES/@\1/home/ci/source/@g'
echo "##[endgroup]"

# build containter
echo "##[group]Build Docker container 'report-generator'"
docker build \
    -t report-generator \
    $top_level/tools/report-generator
echo "##[endgroup]"

# execute build script
# use 'docker run -it ..' for interactive debugging
echo "##[group]Generate Reports"
docker run --rm \
    -u $(id -u):$(id -g) \
    -v $source:/home/ci/source \
    -v $directory:/home/ci/data \
    -v $history:/home/ci/history \
    -v $output:/home/ci/report \
    report-generator \
        -reports:/home/ci/data/**/Cobertura_*.xml \
        -targetdir:/home/ci/report \
        "-reporttypes:Html;HtmlChart;JsonSummary;PngChart;Badges;MarkdownDeltaSummary" \
        -historydir:/home/ci/history \
        -title:MIES \
        -tag:$(git rev-parse --short HEAD) \
        $license
echo "##[endgroup]"

# output some variables (this makes CI integration easier)
if [ -f "$GITHUB_OUTPUT" ]; then
    echo "history=$history" >> $GITHUB_OUTPUT
    echo "report=$output" >> $GITHUB_OUTPUT
    if [ -f "$output/DeltaSummary.md" ]; then
        echo "##[group]Copy Summary"
        cat "$output/DeltaSummary.md" | tee -a $GITHUB_STEP_SUMMARY
        echo "##[endgroup]"
    fi
fi

#!/bin/bash

## check if any files are provided

if [ "$#" -eq 0 ]; then
    echo "No JUnit *.xml files are provided"
    exit 1
fi

## check each JUnit xml file

while [ "$#" -gt 0 ]; do
    # check if file exists
    if [ ! -f "$1" ]; then
        echo "JUnit file not found: $1"
        exit 2
    fi

    echo "Verify $1..."

    suites="$(grep "<testsuite " "$1")"
    errors="$(echo "$suites" | grep -vc 'errors="0"')"
    failures="$(echo "$suites" | grep -vc 'failures="0"')"

    echo "Status $1: $errors errors, $failures failures"

    if [ "$errors" -gt 0 ] || [ "$failures" -gt 0 ]; then
        exit 3
    fi

    shift 1
done

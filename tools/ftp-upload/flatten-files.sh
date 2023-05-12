#!/bin/bash

function help() {
    echo -e "$0 <dir>\nFlatten folder structure in directory <dir>" > /dev/fd/2
    exit 1
}

if [ ! $# = "1" ]; then
    help
fi

dir="$1"

if [ ! -d "$dir" ]; then
    echo "Directory $dir not found" > /dev/fd/2
    exit 2
fi

# move files upwards
find "$dir" -mindepth 2 -type f | \
    while read file; do
        newPath="$dir/$(basename "$file")"

        # check if new path is already used
        if [ -f "$newPath" ]; then
            filename=$(basename -- "$file")
            extension="${filename##*.}"
            filename="${filename%.*}"
            num=1
            newPath="$dir/$filename-($num).$extension"

            # iterate until an unused file path is found
            while [ -f "$newPath" ]; do
                num=$(( num + 1 ))
                newPath="$dir/$filename-($num).$extension"
            done
        fi

        # move file to new path
        echo "$file -> $newPath"
        mv "$file" "$newPath"
    done

# delete all nested folders
find "$dir" -mindepth 1 -type d -delete

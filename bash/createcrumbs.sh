#!/bin/bash
if [[ $# != 2 ]]; then
    echo "Both a source and a target directory are required."
fi

SOURCE_DIR=$1
TARGET_DIR=$2

if [[ ! -d $SOURCE_DIR ]]; then
    echo "The source directory $SOURCE_DIR cannot be found."
elif [[ ! -d $TARGET_DIR ]]; then
    echo "The source directory $TARGET_DIR cannot be found."
else
    echo "OK, most things look OK."
    files=$(ls *.md)
    for file in $files
    do
        echo "$file"
    done
fi


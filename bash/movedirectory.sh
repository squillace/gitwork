#!/bin/bash
if [[ $# != 2 ]]; then
    echo "Both a source and a target directory are required."
fi

function move_files(){
    echo "Type the file pattern and then [ENTER]:"
    read pattern
    #set -x
    # TODO: this doesn't work if you put it in "$pattern"
    files=$(ls $SOURCE_DIR/$pattern)
    for file in $files
    do
        echo "Source directory: $(find $(git rev-parse --show-toplevel) -type f -name .)/$SOURCE_DIR"
        echo "absolute file: $file"
        echo "file itself: $(basename $file)"
        echo "target URL should be :$(find $(git rev-parse --show-toplevel) -type f -name .)/$TARGET_DIR/$(basename $file)"
        source ~/workspace/gitwork/bash/renamefile-general.sh $file $(find $(git rev-parse --show-toplevel) -type f -name .)/$TARGET_DIR/$(basename $file)
    done
    #set +x
}

SOURCE_DIR=$1
TARGET_DIR=$2

if [[ ! -d $SOURCE_DIR ]]; then
    echo "The source directory $SOURCE_DIR cannot be found."
elif [[ ! -d $TARGET_DIR ]]; then
    echo "The source directory $TARGET_DIR cannot be found. Creating directory..."
    mkdir $TARGET_DIR
    move_files
else
    echo "OK, most things look OK."
    move_files
fi


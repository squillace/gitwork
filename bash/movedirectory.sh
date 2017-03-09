#!/bin/bash
if [[ $# != 2 ]]; then
    echo "Both a source and a target directory are required."
fi

function move_files(){
    echo "Type the file pattern and then [ENTER]:"
    read pattern
    echo "Type the sed targetscheme: "
    read targetscheme
    echo "Type the sed replacement scheme: "
    read replacementScheme
    #set -x
    # TODO: this doesn't work if you put it in "$pattern"
    files=$(find $SOURCE_DIR -type f -name $pattern)
    for file in $files
    do
        echo "Source directory: $(dirname $file)"
#        echo "echo REPLACEMENT: sed \"$targetscheme\" and \"$replacementScheme\"
        
        echo "$($(basename $file) | sed 's/$targetscheme/$replacementScheme/g')"
        echo "absolute file: $file"
        echo "file name itself: $(basename $file)"
        echo "target URL should be :$TARGET_DIR$(basename $file)"
        echo "command: $file $TARGET_DIR$(basename $file)"
        #~/Documents/GitHub/gitwork/dotnet/move/move/bin/Debug/move.exe $file $TARGET_DIR$(basename $file)
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


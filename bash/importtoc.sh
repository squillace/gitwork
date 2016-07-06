#!/bin/bash

# for testing, pauses with a message until ENTER is pressed
function pause(){
   read -p "$*" input </dev/tty
}

# creates a heading for the toc
function create_heading(){
   echo "# [$1]($2)" >> $2
}

if [ $# -ne 2 ]; then
    echo "there are not two file targets"
elif [ $(ls $1 | wc -l) -eq 0 ]; then
    echo "Can't find the input file $1."
    exit 1
elif [[ ! -d $2 ]]; then
    echo "hey, the directory doesn't exist!!"
fi

echo "Import source file: $1"
echo "Export file target: $2"
SOURCE_FILE=$1
TARGET_FILE="$2/TOC.md"

# touch "$2"


# create_heading "New Heading" "http://newyorktimes.com"

cat $SOURCE_FILE | jq '.'
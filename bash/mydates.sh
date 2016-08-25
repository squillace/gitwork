#!/bin/bash
if [ $# -ne 1 ]; then
    echo "We need at least one ms.author to look for."
    exit 1
fi

author=$1
#set -x
files=$(find $(git rev-parse --show-toplevel) -type f -name "*.md" -exec grep -lP "(?<=ms.author=\")$author(?=\")" {} +) 
#echo "$files"

for file in $files
do
#set -x
  date=$(cat "$file" | grep -oP "(?<=ms.date=\").*(?=\")")
  echo "$file: $date"
done



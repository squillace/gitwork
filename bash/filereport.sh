#!/bin/bash

echo "\"File\",\"Title\",\"Service Slug\",\"Author\"" > test.csv
while read file # not yet sure why the IPS doesn't work here.
do
    #echo "File: $file"
    shortfile="$(basename $file)"
    title="$(grep -P -m 1 "^#{1} *.*\w*?" $file | sed "s/#//g" | sed "s/^ //g" | sed "s/^.*>//g")"
    #echo "title: \"$title\""
    title=${title//[$'\t\r\n']}
    #echo "title: \"$title\""
    #trimmedTitle="$(echo $title | sed s/#//g | awk '{$1=$1};1')"
    #echo "Internal Title: \"$trimmedTitle\""
    author="$(grep -oP "(?<=ms.author:).*" $file)"
    author=${author//[$'\t\r\n ']}
    service="$(grep -oP "(?<=services:).*" $file)"
    echo "\"$shortfile\",\"$title\",\"$service\",\"$author\"" 
   # echo "\"$shortfile\",\"$title\",\"$service\",\"$author\"" # >> test.csv

done <<< "$(find $(git rev-parse --show-toplevel)/articles -type f -name "*.md")"
#!/bin/bash

echo "\"File\",\"Title\",\"Service Slug\",\"Author\"" > test.csv
while read file # not yet sure why the IPS doesn't work here.
do
    echo "File: $file"
    shortfile="$(basename $file)"
    H1=""
    H2=""
    H3=""
    H4=""
    H5=""
    H6=""
    while read line;
    do 
        #echo $file
        #echo "$line"
        heading="${line//[^#]}"
        if [[ "${#heading}" == "1" ]]; then 
            echo "yeah"
            H1=$(grep -oP "(?<=\[).*(?=\])")
        elif [[ "${#heading}" == "2" ]]; then
            H2=$(grep -oP "(?<=\[).*(?=\])")
        elif [[ "${#heading}" == "3" ]]; then
            H3=$(grep -oP "(?<=\[).*(?=\])")
        elif [[ "${#heading}" == 4 ]]; then
            H4=$(grep -oP "(?<=\[).*(?=\])")
        elif [[ "${#heading}" == 5 ]]; then
            H5=$(grep -oP "(?<=\[).*(?=\])")
        else
            H6=$(grep -oP "(?<=\[).*(?=\])")
        fi
        echo "$file, $H1, $H2, $H3, $H4, $H5, $H6"
        #echo "$heading"
        #echo "${#heading}"
    done < $file

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

done <<< "$(find $(git rev-parse --show-toplevel)/articles -type f -name "TOC.md")"
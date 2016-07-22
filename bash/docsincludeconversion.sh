#!/bin/bash
#links=$(ls *.md | xargs -I {} grep -noHP "(?<=\[AZURE.INCLUDE \[learn-about-deployment-models\]\().*?(?=\)\])" {})
# links=$(grep -oP "(?<=\]\().*?(?=\))" 2>/dev/null $1 | sed "s/#.*?//g" | grep -o *.md | uniq)
#links=$(grep -oP "(?<=\]\().*?(?=\))" 2>/dev/null $1)

file=""
linenum=""
includetext=""
title=""
while IPS='\:' read entry
do
    file="$( cut -d ':' -f 1 <<< "$entry" )"
    linenum=$(echo "$entry" | grep -oP "(?<=:).+(?=:)")
    #linenum=${linenum%\:*}
    includepath=$(echo "$entry" | grep -oP "(?<=\().*(?=\))")
    title=$(echo "$entry" | grep -oP "(?<= \[).*(?=\]\()")
#    echo "stuff: ${file[@]}"
    #echo "line: $linenum"
    echo "Include content: $includepath"
    #echo " file: $file"
    #include=$(<"$includetext")
#    set -x
    SED_NEW_PATH=${includepath//\//\\/} # same as current media path
    #include="\[!include\[$title\]($includetext)\]" # -- is the format
    
    gsed -i'' -e "s/\[AZURE.INCLUDE \[$title\]\(.*\)\]/\[\!include\[$title\]\($SED_NEW_PATH)\]/g" "$file"
    #sed -i'' -e "$linenum"d $file
    #sed -i'' "$linenum"i\ "$include" "$file"
    #echo "$include" >> "$file"
    read
    #FILE_PATH=$(find $(git rev-parse --show-toplevel) -type f -name "${file[@]}")
    #MEDIAPATH="$(dirname $FILE_PATH)/media/${file[@]%.md}"
done <<< "$(ls $1 | xargs -I {} grep -noHP "\[AZURE.INCLUDE \[.*\]\(.*\)\]" {})"

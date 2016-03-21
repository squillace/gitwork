#!/bin/bash
#links=$(ls *.md | xargs -I {} grep -noHP "(?<=\[AZURE.INCLUDE \[learn-about-deployment-models\]\().*?(?=\)\])" {})
# links=$(grep -oP "(?<=\]\().*?(?=\))" 2>/dev/null $1 | sed "s/#.*?//g" | grep -o *.md | uniq)
#links=$(grep -oP "(?<=\]\().*?(?=\))" 2>/dev/null $1)
file=""
linenum=""
includetext=""
while IPS='\:' read entry
do
    file=${entry%\:*\:.*}
    linenum=$(echo "$entry" | sed "s/$file\://g")
    linenum=${linenum%\:*}
    includetext=${entry#*\:*\:}
#    echo "stuff: ${file[@]}"
    echo "line: $linenum"
    echo "include: $includetext"
    echo " file: $file"
    include=$(<"$includetext")
    sed -i'' -e "$linenum"d $file
    echo "$include"
    
    #FILE_PATH=$(find $(git rev-parse --show-toplevel) -type f -name "${file[@]}")
    #MEDIAPATH="$(dirname $FILE_PATH)/media/${file[@]%.md}"
done <<< "$(ls $1 | xargs -I {} grep -noHP "(?<=\[AZURE.INCLUDE \[learn-about-deployment-models-both-include\]\().*?(?=\)\])" {})"

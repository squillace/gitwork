#!/bin/bash
GITROOT=$(git rev-parse --show-toplevel)

file=""
linenum=""
includefilepath=""

remap=$(<~/completeredirects.txt)


while read file # not yet sure why the IPS doesn't work here.
do
    echo "File: $file"
    links=$(grep -oP "(?<=\]\().*?(?=\))" 2>/dev/null $file | sed "s/#.*?//g" | grep -v http | grep -v media)
    #echo "$links"

    for link in $links
        do         
        if [[ $(ls 2>/dev/null $link | wc -l) -eq 0 ]]; then
            #echo "link is wrong: $link"
            file_only=$(echo $link | grep -oP "[\w-]+\.md" | grep -v \#)
            if [[ "$file_only" == "" ]]; then 
                #echo "we caught crappy internal link"
                continue 
            fi
            #echo "here's the file only: $file_only"
            
            if [[ $(find $(git rev-parse --show-toplevel) -name "$file_only" -type f | wc -l) -eq 0 ]]; then
                echo "$file_only does not exist in the repository"
                # here we know the link is incorrect, and we know that 
                file_stem=${file_only%.md}
                redirectline=$(echo "$remap" | grep -P "$file_stem")
                if [[ ! "$redirectline" == "" ]]; then
                    newfilename=$(echo $redirectline | grep -oP "(?<=value=\"/documentation/articles/).*?(?=/)")
                    echo "Hey: $newfilename"
                    # fix them all at once
                    find "$GITROOT" -name "*.md" -type f -exec grep -il "$file_stem" {} + | xargs -I {} gsed -i'' -e s/"$file_stem"/"$newfilename"/i {}
                fi
            fi
        fi
    done

done <<< "$(ls $1)"
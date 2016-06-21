#!/bin/bash
GITROOT=$(git rev-parse --show-toplevel)

file=""
linenum=""
includefilepath=""

# remap=$(<~/completeredirects.txt)


while read file # not yet sure why the IPS doesn't work here.
do
    echo "File: $file"
    # grabs all markdown links in the file, of any kind. Does not do external links.
    links=$(grep -oP "(?<=\]\().*?(?=\))" 2>/dev/null $file | sed "s/#.*?//g" | grep -v http | grep -v media)
    #echo "$links"

    for link in $links
        do         

        # first see if you can find a file at the link location
        if [[ $(ls 2>/dev/null $link | wc -l) -eq 0 ]]; then
            #echo "link is wrong: $link"

            # skipping internal links but grab any that have a file attached
            file_only=$(echo $link | grep -oP "[\w-]+\.md" | grep -v \#)
            #echo "here's the file only: $file_only"
            if [[ "$file_only" == "" ]]; then 
                #echo "we caught crappy internal link"
                continue 
            fi            
            if [[ $(find $(git rev-parse --show-toplevel) -name "$file_only" -type f | wc -l) -eq 0 ]]; then
                echo "$file_only does not exist in the repository"
                # here we know the link is incorrect, and we know that 
                file_stem=${file_only%.md}
                continue # until we implement the rewriting algorithm
                redirectline=$(echo "$remap" | grep -P "\/$file_stem\/")
                if [[ ! "$redirectline" == "" ]]; then
                    echo "redirect line: $redirectline" 
                    newfilename=$(echo $redirectline | grep -oP "(?<=value=\"/documentation/articles/).*?(?=/)").md
                    echo "new link target: $newfilename"
                    echo "original link target: $file_only"
                    absolute_original_file=$(find $(git rev-parse --show-toplevel) -type f -name "$file")
                    absolute_new_file=$(find $(git rev-parse --show-toplevel) -type f -name "$newfilename")
                    relativeLink=$(realpath $absolute_new_file --relative-to=$file)
                    echo "here's the relative link that should be there: $relativeLink"
                    
                    # SED escaping
                    SED_OLD_PATH=${file_stem//\//\\/}
                    # SED escaping
                    SED_NEW_PATH=${newfilename//\//\\/}
                    #find "$GITROOT" -name "*.md" -type f -exec grep -il "$file_stem" {} + | xargs -I {} sed -i'' -e s/"$file_stem"/"$newfilename"/i {}
                fi
            else    
                echo "found $(realpath $(find $(git rev-parse --show-toplevel) -name "$file_only" -type f))"
            fi
        else
            echo "found $(ls $link)"
        fi
        

    done

done <<< "$(ls $1)"
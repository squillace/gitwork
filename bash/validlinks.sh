#!/bin/bash

links=$(grep -oP "(?<=\]\().*?(?=\))" 2>/dev/null $1)

#echo "$links"

for link in $links
    do 
#    echo $link       
    if [[ "$link" =~ .*.md.* ]]; then
        echo "it's a local file: $link"
        find $(git rev-parse --show-toplevel) -name "$link" -type f
        echo "got it with ls? $(ls $link | wc -l)"
    fi
done


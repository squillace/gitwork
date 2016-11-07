#!/bin/bash

for file in $(find $(git rev-parse --show-toplevel) -type f -name "*sap*.md") 
do 

    PAGE_TITLE=$(grep -oP "(?<=pageTitle=\").*?(?=\")" $file)
    EXTRACTED_TITLE=$(grep -P -m 1 "^#{1} *.*\w*?" $file | sed "s/#//g" | sed "s/^ //g" | sed "s/^.*>//g")
    DESCRIPTION=$(grep -oP "(?<=description=\").*?(?=\")" $file)
    TAGS=$(grep -oP "(?<=tags=\").*?(?=\")" $file)

    echo "$file, $PAGE_TITLE, $EXTRACTED_TITLE, $DESCRIPTION" 
done
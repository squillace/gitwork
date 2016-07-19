#!/bin/bash

# Documentation: 
# This script takes a filespec (or directory) and locates the Azure.Include for all common files inside each  
# file found, removes the AZURE.INCLUDE and replaces it with the contents of that include file, moves the media from the 
# include directory, and leaves the git status ready to commit the change after examination. Docs inline:

# links=$(ls *.md | xargs -I {} grep -noHP "(?<=\[AZURE.INCLUDE \[learn-about-deployment-models\]\().*?(?=\)\])" {})
# links=$(grep -oP "(?<=\]\().*?(?=\))" 2>/dev/null $1 | sed "s/#.*?//g" | grep -o *.md | uniq)
# links=$(grep -oP "(?<=\]\().*?(?=\))" 2>/dev/null $1)

### ==================================== 

# variables needed later
file=""
linenum=""
includefilepath=""

# for each file create a $file variable that has the file name
while IPS='\:' read file # not yet sure why the IPS doesn't work here.
do
    echo "$file"
    # grab the line on which the specific AZURE.INCLUDE occurs
    linenum=$(grep -onP "\[AZURE.INCLUDE \[virtual-machines-common.*" $file | sed "s/:.*//g")
    echo $linenum
    
    # figure out how many lines you want to cut
    lines_to_cut=$(grep -oP "\[AZURE.INCLUDE \[virtual-machines-common.*" $file)
    #echo $lines_to_cut
    
    # obtain the include file path
    includefilepath=$(echo "$lines_to_cut" | grep -oP "(?<=\().*?(?=\))")
    
    # read the include file content into the variable
    include_content=$(<"$includefilepath")
    #echo $include_content
    #sed -i'' -e "$linenum"d $file # remove the line with the include_content
    
    # capture the top and bottom of the file you're merging into
    top_of_file=$(head -n "$linenum" "$file" | sed "$linenum"d )
    bottom_of_file=$(sed -n "$((linenum + 1))"',$p' "$file")
    
    # rewrite the file; in bash, it's easier to rewrite the entire file than it is to "insert" changes into the file. YMMV.
    echo "$top_of_file" > "$file"
    echo "$include_content" >> "$file"
    echo "$bottom_of_file" >> "$file"
    #sed -i "$linenum"i "$include_content" $file 
    
    # go and locate the media that WAS referenced in the include content
    MEDIAPATH="../../includes/media/${file[@]	}"
    CURRENTFILESTEM=${file[@]%.md}
    
    INCLUDEFILESTEM=${CURRENTFILESTEM/windows/common} ### replaces "linux"" with "common". YOU must decide how you wish to modify this, if at all.
    MEDIAPATH=${MEDIAPATH/windows/common} ### ditto
    FILESTEM=${file%.md}
    echo "Media path: $MEDIAPATH"
    echo "file stem: $FILESTEM"

    if [ $(ls "$MEDIAPATH" 2>/dev/null | wc -l) -ne 0 ]; then

    # locate media files, and then move them to the proper subdirectory of the rewritten file
    for files in $(ls "$MEDIAPATH"*)
    do
        echo "Media file: ${files[@]}"
        CURRENT_MEDIAFILE=${files[@]} # this is the current media file name
        NEWFILESTEM=${CURRENT_MEDIAFILE%.md}
        CURRENT_MEDIAPATH="$MEDIAPATH/$CURRENT_MEDIAFILE" # current media subdir from topic dir
        NEWMEDIAPATH="./media/$FILESTEM/$CURRENT_MEDIAFILE" # the NEW media path of this media file
        echo "moving ${files[@]} to $NEWMEDIAPATH"
        mkdir "./media/$FILESTEM" # make sure the directory exists first, or you can't move
        echo "moving \"$CURRENT_MEDIAPATH\" to \"$NEWMEDIAPATH\""
        git mv -v "$CURRENT_MEDIAPATH" "$NEWMEDIAPATH"
        
        #rewrite the media path: 
        sed -i'' -e s/"$INCLUDEFILESTEM"/"$CURRENTFILESTEM"/i "$file"
    done

fi
# This is actually the beginning of the script: given a filespec/directory, locate all files that have an include of a certain type. 
# This can be generalized to all includes if you want. 
done <<< "$(ls *windows* | xargs -I {} grep -loP "\[AZURE.INCLUDE \[virtual-machines-common.*" {})"

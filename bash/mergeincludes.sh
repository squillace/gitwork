#!/bin/bash
# links=$(ls *.md | xargs -I {} grep -noHP "(?<=\[AZURE.INCLUDE \[learn-about-deployment-models\]\().*?(?=\)\])" {})
# links=$(grep -oP "(?<=\]\().*?(?=\))" 2>/dev/null $1 | sed "s/#.*?//g" | grep -o *.md | uniq)
# links=$(grep -oP "(?<=\]\().*?(?=\))" 2>/dev/null $1)
file=""
linenum=""
includefilepath=""
while IPS='\:' read file # not yet sure why the IPS doesn't work here.
do
    echo "$file"
    linenum=$(grep -onP "\[AZURE.INCLUDE \[virtual-machines-common.*" $file | sed "s/:.*//g")
    echo $linenum
    lines_to_cut=$(grep -oP "\[AZURE.INCLUDE \[virtual-machines-common.*" $file)
    #echo $lines_to_cut
    includefilepath=$(echo "$lines_to_cut" | grep -oP "(?<=\().*?(?=\))")
    include_content=$(<"$includefilepath")
    #echo $include_content
    #sed -i'' -e "$linenum"d $file # remove the line with the include_content
    top_of_file=$(head -n "$linenum" "$file" | sed "$linenum"d )
    bottom_of_file=$(sed -n "$((linenum + 1))"',$p' "$file")
    
    # rewrite the file. 
    echo "$top_of_file" > "$file"
    echo "$include_content" >> "$file"
    echo "$bottom_of_file" >> "$file"
    #sed -i "$linenum"i "$include_content" $file 
    
    MEDIAPATH="../../includes/media/${file[@]%.md}"
    CURRENTFILESTEM=${file[@]%.md}
    INCLUDEFILESTEM=${CURRENTFILESTEM/linux/common}
    MEDIAPATH=${MEDIAPATH/linux/common}
    FILESTEM=${file%.md}
    echo "Media path: $MEDIAPATH"
    echo "file stem: $FILESTEM"

    if [ $(ls "$MEDIAPATH" 2>/dev/null | wc -l) -ne 0 ]; then

    # locate media files, and then rewrite all inbound links to THOSE files.  
    for files in $(ls "$MEDIAPATH"*)
    do
        echo "Media file: ${files[@]}"
        CURRENT_MEDIAFILE=${files[@]} # this is the current media file name
        NEWFILESTEM=${CURRENT_MEDIAFILE%.md}
        CURRENT_MEDIAPATH="$MEDIAPATH/$CURRENT_MEDIAFILE" # current media subdir from topic dir
        # SED escaping
        NEWMEDIAPATH="./media/$FILESTEM/$CURRENT_MEDIAFILE" # the NEW media path of this media file
        echo "moving ${files[@]} to $NEWMEDIAPATH"
        mkdir "./media/$FILESTEM"
        echo "moving \"$CURRENT_MEDIAPATH\" to \"$NEWMEDIAPATH\""
        git mv -v "$CURRENT_MEDIAPATH" "$NEWMEDIAPATH"
        
        #rewrite the media path: 
        gsed -i'' -e s/"$INCLUDEFILESTEM"/"$CURRENTFILESTEM"/i "$file"
    done

fi

done <<< "$(ls $1 | xargs -I {} grep -loP "\[AZURE.INCLUDE \[virtual-machines-common.*" {})"

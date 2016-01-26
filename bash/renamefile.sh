#!/bin/bash

echo We\'re in working directory "$PWD".
FILE=$1
NEWFILE=$2

if [ -f $FILE ]; then
   echo "File '$FILE' exists; renaming it to $NEWFILE"
else
   echo "The File '$FILE' Does Not Exist"
fi

FILESTEM=${FILE%.md}
MEDIAPATH="media/$FILESTEM/"
echo "testing for $MEDIAPATH*.*"

# if [ $(find $MEDIAPATH -maxdepth 0 -type d -empty 2>/dev/null) ]; then
#    echo "Empty directory"
#else
#    echo "Not empty or NOT a directory"
#fi


if [ $(ls "$MEDIAPATH" 2>/dev/null | wc -l) -ne 0 ]; then
    ls "$MEDIAPATH"
    echo "Moving the files in git..."
    git mv "$FILE" "vms-linux-$NEWFILE"
    for files in $(ls "$MEDIAPATH"*)
    do
        CURRENT_MEDIAFILE=${files[@]##*/}
        NEWFILESTEM=${NEWFILE%.md}
        NEWPATH="media/$NEWFILESTEM/$CURRENT_MEDIAFILE"
        echo "Stem of original file: $FILESTEM"
        echo "Stem of the new file: $NEWFILESTEM"
        echo "New media path: $NEWPATH"
        echo "Current media file: $CURRENT_MEDIAFILE"
        echo "git mv\'ing ${files[@]}..."
        mkdir "media/$NEWFILESTEM"
        git mv "${files[@]}" "$NEWPATH"       
    done
    git status
else # the directory may exist but it is empty
    echo "moving the file in git..."
    git mv "$FILE" "vms-linux-$NEWFILE"
    git status   
fi

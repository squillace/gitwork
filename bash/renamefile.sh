#!/bin/bash
if (( $# != 2 )); then
    echo "Illegal number of parameters; exiting..."
    exit 1;
fi

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
GITROOT=$(git rev-parse --show-toplevel)
echo "Root of the git directory is: $GITROOT"


    
if [ $(ls "$MEDIAPATH" 2>/dev/null | wc -l) -ne 0 ]; then
    ls "$MEDIAPATH"
    # escapes necessary to use SED properly
    _r1="${_r1//\//\\/}"
    echo "Moving the files in git..."
    git mv "$FILE" "vms-linux-$NEWFILE"
    echo "searching the repository for \"/$FILE\" references..."
    echo "${_r1}$FILE"
    find "$GITROOT" -name "*.md" -type f -exec grep -l "\\/$FILE" {} + | xargs -I {} sed -i'' -e s/"${_r1}""$FILE"/"${_r1}""$NEWFILE"/g {}    
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

else # the directory may exist but it is empty
    # escapes necessary to use SED properly
    _r1="${_r1//\//\\/}"
    echo "moving the file in git..."
    git mv "$FILE" "vms-linux-$NEWFILE"
    git status   
      echo ="${_r1}"\?""$FILE"
      echo "searching the repository for \"/$FILE\" references..."
    find "$GITROOT" -name "*.md" -type f -exec grep -l "\\/$FILE" {} + | xargs -I {} sed -i'' -e s/"${_r1}""$FILE"/"${_r1}""$NEWFILE"/g {}
fi

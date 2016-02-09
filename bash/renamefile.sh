#!/bin/bash
#set -x 

# variables
GITROOT=$(git rev-parse --show-toplevel)
echo "Root of the git directory is: $GITROOT"

# for testing, pauses with a message until ENTER is pressed
function pause(){
   read -p "$*" input </dev/tty
}

if (( $# != 2 )); then
    echo "Illegal number of parameters; exiting..."
    exit 1;
fi

echo We\'re in working directory "$PWD".
FILE=$1
NEWFILE=$2

if [ $(find "$GITROOT" -name "$FILE" -type f | wc -l) -ne 0 ]; then
   echo "File '$FILE' exists; renaming it to $NEWFILE"
else
   echo "The File '$FILE' Does Not Exist" >> $LOG
   continue
fi

RedirectLOG=~/redirects.txt

FILESTEM=${FILE%.md}
NEWFILESTEM=${NEWFILE%.md}
MEDIAPATH="media/$FILESTEM/"
echo "testing for $MEDIAPATH*.*"


## first, move the file
echo "Moving the files in git..."
git mv "$FILE" "$NEWFILE"
#git add $NEWFILE
#git commit -m "Renaming $FILE into $NEWFILE."
git status

#pause "Now, go and examine the file $FILE and $NEWFILE..."


    
# search for and rewire all inbound links 
echo "searching the repository for \"/$FILE\" references..."
find "$GITROOT" -name "*.md" -type f -exec grep -l "$FILE" {} + | xargs -I {} sed -i'' -e s/"$FILE"/"$NEWFILE"/g {}
    
# test for and move any media files associated with the original file
if [ $(ls "$MEDIAPATH" 2>/dev/null | wc -l) -ne 0 ]; then
#    ls "$MEDIAPATH"
    # escapes necessary to use SED properly
    _r1="${_r1//\//\\/}"
    
    # locate media files, and then rewrite all inbound links to THOSE files.  
    for files in $(ls "$MEDIAPATH"*)
    do
        CURRENT_MEDIAFILE=${files[@]##*/}
        CURRENT_MEDIAPATH="media/$FILESTEM/$CURRENT_MEDIAFILE"
        SED_OLD_PATH=${CURRENT_MEDIAPATH//\//\\/}
        NEWMEDIAPATH="media/$NEWFILESTEM/$CURRENT_MEDIAFILE"
        SED_NEW_PATH=${NEWMEDIAPATH//\//\\/}
        echo "Stem of original file: $FILESTEM"
        echo "Stem of the new file: $NEWFILESTEM"
        echo "New media path: $NEWMEDIAPATH"
        echo "Current media file: $CURRENT_MEDIAFILE"
        echo "git mv\'ing ${files[@]}..."
        mkdir "media/$NEWFILESTEM"
        git mv "${files[@]}" "$NEWMEDIAPATH"

        # rewrite inbound media links from the moved media file.
        find "$GITROOT" -name "*.md" -type f -exec grep -l "$CURRENT_MEDIAPATH" {} + | xargs -I {} sed -i'' -e s/"$SED_OLD_PATH"/"$SED_NEW_PATH"/g {}
    done

fi

# clean up the sed modifications
find $(git rev-parse --show-toplevel) -name "*.md-e" -type f -exec rm {} +

# commit per file renamed.
#git add -A :/
#git commit -m "Renaming $FILE --> $NEWFILE"



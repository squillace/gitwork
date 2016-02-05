#!/bin/bash
#set -x 
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

RedirectLOG=~/redirects.txt

FILESTEM=${FILE%.md}
NEWFILESTEM=${NEWFILE%.md}
MEDIAPATH="media/$FILESTEM/"
echo "testing for $MEDIAPATH*.*"
GITROOT=$(git rev-parse --show-toplevel)
echo "Root of the git directory is: $GITROOT"

## first, move the file
echo "Moving the files in git..."
git mv "$FILE" "$NEWFILE"
git status

# create the redirect string

docURLFragment="/documentation/articles"
echo "<add key=\"$docURLFragment/$FILESTEM/\" value=\"$docURLFragment/$NEWFILESTEM/\" /> <!-- $(date +%D) -->" >> $RedirectLOG
    
# search for and rewire all inbound links 
echo "searching the repository for \"/$FILE\" references..."
find "$GITROOT" -name "*.md" -type f -exec grep -l "$FILE" {} + | xargs -I {} sed -i'' -e s/"$FILE"/"$NEWFILE"/g {}
    
# test for and move any media files associated with the original file
if [ $(ls "$MEDIAPATH" 2>/dev/null | wc -l) -ne 0 ]; then
#    ls "$MEDIAPATH"
    # escapes necessary to use SED properly
    _r1="${_r1//\//\\/}"

    # search for and rewire all inbound links 
    echo "searching the repository for \"/$FILE\" references..."
    find "$GITROOT" -name "*.md" -type f -exec grep -l "$FILE" {} + | xargs -I {} sed -i'' -e s/"$FILE"/"$NEWFILE"/g {}    
    for files in $(ls "$MEDIAPATH"*)
    do
        CURRENT_MEDIAFILE=${files[@]##*/}
        
        NEWPATH="media/$NEWFILESTEM/$CURRENT_MEDIAFILE"
        echo "Stem of original file: $FILESTEM"
        echo "Stem of the new file: $NEWFILESTEM"
        echo "New media path: $NEWPATH"
        echo "Current media file: $CURRENT_MEDIAFILE"
        echo "git mv\'ing ${files[@]}..."
        mkdir "media/$NEWFILESTEM"
        git mv "${files[@]}" "$NEWPATH"

    done

fi

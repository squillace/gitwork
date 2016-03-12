#!/bin/bash
#echo $1
#for element in $1;
#do
#    echo $element
#done

SOURCE_FILE_LIST=$1


declare -a files
while IFS="=" read -r file
do
    echo "stuff: ${file[@]}"
    FILE_PATH=$(find $(git rev-parse --show-toplevel) -type f -name "${file[@]}")
    echo "here's the damn path"
    MEDIAPATH="$(dirname $FILE_PATH)/media/${file[@]%.md}"
    echo "$FILE_PATH"
    echo "$MEDIAPATH"

if [ $(ls "$MEDIAPATH" 2>/dev/null | wc -l) -ne 0 ]; then
    echo "media path= $MEDIAPATH"
   
    # locate media files, and then rewrite all inbound links to THOSE files.  
    for files in $(ls "$MEDIAPATH"*)
    do
        echo "Media file: $(git ls-files ${files[@]##*/})"
        CURRENT_MEDIAFILE=${files[@]##*/} # this is the current media file name
        CURRENT_MEDIAPATH="media/$FILESTEM/$CURRENT_MEDIAFILE" # current media subdir from topic dir
        # SED escaping
        SED_OLD_PATH=${CURRENT_MEDIAPATH//\//\\/} # same, with / replaced for SED work
        NEWMEDIAPATH="./media/$NEWFILESTEM/$CURRENT_MEDIAFILE" # the NEW media path of this media file
        # SED escaping
        SED_NEW_PATH=${NEWMEDIAPATH//\//\\/} # same as current media path
#       echo "Stem of original file: $FILESTEM"
#       echo "Stem of the new file: $NEWFILESTEM"
#       echo "New media path: $NEWMEDIAPATH"
#       echo "Current media file: $CURRENT_MEDIAFILE"
       echo "git mv\'ing ${files[@]} to $NEWMEDIAPATH"
#       echo "rewrite the new file's medai links to $MEDIAPATH"
       local_NEWMEDIAPATH=$NEWMEDIAPATH/$CURRENT_MEDIAFILE
       local_NEWMEDIAPATH="./$local_NEWMEDIAPATH"
       local_SED_NEW_PATH=${local_NEWMEDIAPATH//\//\\/}
	       
 
        # You can add, but you may NOT commit    
    done

fi


done < "$SOURCE_FILE_LIST"
#echo ${arr[@]}








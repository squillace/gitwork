#!/bin/bash
#set -x 

timestamp() {
  date +"%T"
}

# variables
GITROOT=$(git rev-parse --show-toplevel)
echo "Root of the git directory is: $GITROOT"

# for testing, pauses with a message until ENTER is pressed
function pause(){
   read -p "$*" input </dev/tty
}

if (( $# != 2 )); then
    echo "Illegal number of parameters; exiting..."
    echo "parameters are: $@"
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
echo "testing for $MEDIAPATH*.*: $(ls $MEDIAPATH | wc -l) files -- $(ls $MEDIAPATH)"

# BUG: One-off for known media directories with capitalizations
if [[ $FILESTEM =~ .*[-lob-]*.* || $FILESTEM =~ .*weblogic.* ]]; then
    # pause "hey, $FILE is -lob- or webLogic... rewriting file"
    FILESTEM=${FILESTEM//-lob-/-LOB-}
    FILESTEM=${FILESTEM//weblogic/webLogic}
    #pause "FILESTEM is now $FILESTEM....."
fi

check_tags_value="No worries."
# OK, ready to work. First, set the bit for the PR to check the tags value:
if [[ ! "$tags" =~ .*azure-resource-manager.* && ! "$tags" =~ .*azure-service-management.* ]]; then

    if [[ "$NewNameSlug" =~ .*asm.* ]]; then
        check_tags_value="Check them."
        #pause "tags: $tags; slug: $NewNameSlug"
    fi
    # log the fact that we can't do anything with this file and move on
    no_tags $LOG $Assigned $URL $contentID.md $Author MSTgtPltfrm $(norm_hypens $NewNameSlug) $Include $Windows $Linux $RedirectTarget
    #pause "Press ENTER to continue..."
    #continue
fi

# continue    

# first, create branch for the rename:
temp_name=$(write_new_name)
temp_name=${temp_name%.md} 
echo $temp_name
#git checkout -b "$Assigned-$temp_name" release-vm-refactor

## first, move the file
echo "Moving \"$FILE\" to \"$NEWFILE\" in git..."

#continue

git mv "$FILE" "$NEWFILE"
    
# search for and rewire all inbound links 
echo "searching the repository for \"/$FILE\" references..."

find "$GITROOT" -name "*.md" -type f -exec grep -il "$FILE" {} + | xargs -I {} sed -i'' -e s/"$FILE"/"$NEWFILE"/i {}
git ls-files -m "$GITROOT" *.md | xargs -I {} git add {}
#git add $NEWFILE
git commit -m "Renaming $FILE into $NEWFILE."
#git status

#pause "Now, go and examine the file $FILE and $NEWFILE..."

# test for and move any media files associated with the original file
if [ $(ls "$MEDIAPATH" 2>/dev/null | wc -l) -ne 0 ]; then
#    ls "$MEDIAPATH"
   
    # locate media files, and then rewrite all inbound links to THOSE files.  
    for files in $(ls "$MEDIAPATH"*)
    do
        CURRENT_MEDIAFILE=${files[@]##*/}
        CURRENT_MEDIAPATH="media/$FILESTEM/$CURRENT_MEDIAFILE"
        # SED escaping
        SED_OLD_PATH=${CURRENT_MEDIAPATH//\//\\/}
        NEWMEDIAPATH="media/$NEWFILESTEM/$CURRENT_MEDIAFILE"
        # SED escaping
        SED_NEW_PATH=${NEWMEDIAPATH//\//\\/}
  #      echo "Stem of original file: $FILESTEM"
  #      echo "Stem of the new file: $NEWFILESTEM"
  #      echo "New media path: $NEWMEDIAPATH"
  #      echo "Current media file: $CURRENT_MEDIAFILE"
  #      echo "git mv\'ing ${files[@]} to $NEWMEDIAPATH"
        # TODO: Here's the problem. Warning: we are failing to git mv the media files
        # Resolution: on mac, and window, there's case-preserving but insensitive, which means there's no easy way to obtain
        # directories with capitalizations without already having them. BUT... 
        # as: ls media | grep -o '[^ ]*[A-Z][^ ]*'
        # shows us that only LOB and webLogic have caps in them in the articles/virtual-machines/media folder, we're just special casing those, above.
        
        mkdir "media/$NEWFILESTEM"
        git mv "media/$FILESTEM/$CURRENT_MEDIAFILE" "media/$NEWFILESTEM/$CURRENT_MEDIAFILE"

        # rewrite inbound media links from the moved media file.
        find "$GITROOT" -name "*.md" -type f -exec grep -il "$CURRENT_MEDIAPATH" {} + | xargs -I {} sed -i'' -e s/"$SED_OLD_PATH"/"$SED_NEW_PATH"/i {}
	        
        git ls-files -m "$GITROOT" *.md | xargs -I {} git add {}
        git commit -m "Moving $CURRENT_MEDIAPATH to $NEWMEDIAPATH"
    done

fi


# clean up the sed modifications
find $(git rev-parse --show-toplevel) -name "*.md-e" -type f -exec rm {} +

# Do the push and PR creation:

#echo "pushing to $Assigned-$temp_name:$Assigned-$temp_name"
#pause "Assigned: $Assigned"
#$(git push -v squillace "$Assigned-$temp_name":"$Assigned-$temp_name")
#echo "$(timestamp): $(hub pull-request -m "[$Assigned]:[$NEWFILESTEM] Tagcheck: \"$tags\"" -b squillace:vm-refactor-staging -h squillace:$Assigned-$temp_name $(git rev-parse HEAD))" >> $LOG 

#hub pull-request -m "trying one more time" -b squillace:release-vm-refactor -h squillace:vm-refactor-staging $(git rev-parse HEAD)

#git checkout vm-refactor-staging
#git status




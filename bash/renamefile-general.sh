#!/bin/bash
#set -x # for debugging if you want it.

# for logging
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

#set -x
#echo "$1: $2"
# quick parameter checking. In linux, you can rename things into an empty string. :-|
if (( $# != 2 )); then
    echo "Illegal number of parameters; exiting..."
    echo "parameters are: $@"
    exit 1;
fi
#set +x

# starting
echo "We\'re in working directory $PWD".
FILE=$1
NEWFILE=$2

if [ $(find "$GITROOT" -name "$FILE" -type f | wc -l) -ne 0 ]; then
   echo "File '$FILE' exists; renaming it to $NEWFILE"
else
   echo "The File '$FILE' Does Not Exist" # >> $LOG
   continue
fi

FILESTEM=${FILE%.md}
NEWFILESTEM=${NEWFILE%.md}
MEDIAPATH="media/$FILESTEM/"
echo "Looking for media files to move..."

# BUG: One-off for known media directories with capitalizations
if [[ $FILESTEM =~ .*[-lob-]*.* || $FILESTEM =~ .*weblogic.* ]]; then
    # pause "hey, $FILE is -lob- or webLogic... rewriting file"
    FILESTEM=${FILESTEM//-lob-/-LOB-}
    FILESTEM=${FILESTEM//weblogic/webLogic}
    #pause "FILESTEM is now $FILESTEM....."
fi

## first, move the file
echo "Moving \"$FILE\" to \"$NEWFILE\" in git..."
echo "searching the repository for \"/$FILE\" references..."

# search for and rewire all inbound links 
# requires gsed or sed that supports case-insensitive command
find "$GITROOT" -name "*.md" -type f -exec grep -il "$FILE" {} + | xargs -I {} gsed -i'' -e s/"$FILE"/"$NEWFILE"/i {}

## Adds files that have had links modified
git ls-files -m "$GITROOT" *.md | xargs -I {} git add {}

# ================ Logging, redirects, and resx filese =============================

echo "$(find "$GITROOT" -name "$FILE" -type f)"
quick_title=$(grep -P -m 1 "^#{1} *.*\w*?" $(find "$GITROOT" -name "$FILE" -type f))

cleaned_quick_title=${quick_title//#/}

link_target_linux=$NEWFILE
linux_article_json_resx_link="${link_target_linux%.md}"
linux_link_json_resx_link="Link_${linux_article_json_resx_link//-/_}"

json_string_linux="\"$linux_link_json_resx_link\": \"article:$linux_article_json_resx_link\","

echo "$json_string_linux" # >> $TOC_LOG

read -d '' resx_strings <<EOF
    <!-- for old file: $FILE   -->
    <data name="$linux_link_json_resx_link" xml:space="preserve">
        <value>$cleaned_quick_title</value>
    </data>
EOF

echo "$resx_strings" # >> $TOC_RESX_LOG

docURLFragment="/documentation/articles"
echo "<add key=\"$docURLFragment/$FILESTEM/\" value=\"$docURLFragment/$linux_article_json_resx_link/\" /> <!-- $(date +%D) -->" # >> $RedirectLOG

# ====================== end of redirect output ==========================

# preserving history and moving the old file to the new file.
git mv "$FILE" "$NEWFILE"

#committing here is optional
git commit -m "Renaming $FILE into $NEWFILE."

# Now: test for and move any media files associated with the original file
# if the listing for the media path is not 0, there are media files to move
if [ $(ls "$MEDIAPATH" 2>/dev/null | wc -l) -ne 0 ]; then
   
    # locate media files, and then rewrite all inbound links to THOSE files.  
    for files in $(ls "$MEDIAPATH"* 2>/dev/null)
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
        
        mkdir "media/$NEWFILESTEM" 2>/dev/null
        git mv "media/$FILESTEM/$CURRENT_MEDIAFILE" "media/$NEWFILESTEM/$CURRENT_MEDIAFILE"

        # rewrite inbound media links from the moved media file.
        # this is only necessary because the internal new file contains links to the old media directory
        find "$GITROOT" -name "*.md" -type f -exec grep -il "$CURRENT_MEDIAPATH" {} + | xargs -I {} gsed -i'' -e s/"$SED_OLD_PATH"/"$SED_NEW_PATH"/i {}
	        
        # adds the newfile.md each time a media link is updated
        git ls-files -m "$GITROOT" *.md | xargs -I {} git add {}
        # committing here is optional 
        git commit -m "Moving $CURRENT_MEDIAPATH to $NEWMEDIAPATH"
    done

fi

# clean up the sed modifications; hangover from the side-effects of "sed"
find $(git rev-parse --show-toplevel) -name "*.md-e" -type f -exec rm {} +

# Do the push and PR creation: 
# optional. Right now, everything has already been performed and git status reports where things exist.

#echo "pushing to $Assigned-$temp_name:$Assigned-$temp_name"
#pause "Assigned: $Assigned"
#$(git push -v squillace "$Assigned-$temp_name":"$Assigned-$temp_name")
#echo "$(timestamp): $(hub pull-request -m "[$Assigned]:[$NEWFILESTEM] Tagcheck: \"$tags\"" -b squillace:vm-refactor-staging -h squillace:$Assigned-$temp_name $(git rev-parse HEAD))" >> $LOG 

#hub pull-request -m "trying one more time" -b squillace:release-vm-refactor -h squillace:vm-refactor-staging $(git rev-parse HEAD)

#git checkout vm-refactor-staging
#git status




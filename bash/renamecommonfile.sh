#!/bin/bash
#set -x 

timestamp() {
  date +"%T"
}

# variables
GITROOT=$(git rev-parse --show-toplevel)
echo "Root of the git directory is: $GITROOT"
RedirectLOG=~/redirects.log

# for testing, pauses with a message until ENTER is presgsed
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

# set file variables
FILESTEM=${FILE%.md}
NEWFILESTEM=${NEWFILE%.md}

# going to have to rework this
MEDIAPATH="media/$FILESTEM/"

if [ $(find "$GITROOT" -name "$FILE" -type f | wc -l) -ne 0 ]; then
   echo "File '$FILE' exists; renaming it to $NEWFILE"
else
   echo "The File '$FILE' Does Not Exist" >> $LOG
   continue
fi

# Algorithm is as follows:
# 1. capture the metdata at the top of the file.
# 1.5 capture the header of the file
# 1.7 strip the header from the body
# 2. Create a windows and linux wrapper file, with a copy of the metadata on top of each.
# 3. Create an include file, and place the remainder of the content in the file.
# 3.5 whack the metadata to insert vm-linux and vm-windows in the metadata
# 4. Move all media from the previous media path to the include/media/path -- don't need any art in the wrappers 
# 5. Submit all as one PR, pushing and then submitting.
#   ISSUES: mainly naming issues. if you have a naming collision, you have to stop processing until you can get through them all.
#   ISSUES: do NOT submit separate commits; do all your work, and submit only one commit. Easier merging in the end.

FILE_METADATA=$(gsed -n '/<properties/,/ms.author.*/p' $(find "$GITROOT" -name "$FILE" -type f))
#pause "$(grep -noP '(?<=ms.author=\").*/>' $FILE | cut -f1 -d:)"

## Create the platform target string.

linux_ms_tgt_platform=$MSTgtPltfrm
windows_ms_tgt_platform=$MSTgtPltfrm

# linuxes
linux_ms_tgt_platform=${linux_ms_tgt_platform// /}
linux_ms_tgt_platform=${linux_ms_tgt_platform///vm-linux}
linux_ms_tgt_platform=${linux_ms_tgt_platform//vm-multiple/vm-linux}
linux_ms_tgt_platform=${linux_ms_tgt_platform//vm-windows/vm-linux}
linux_ms_tgt_platform=${linux_ms_tgt_platform//na/vm-linux}
linux_ms_tgt_platform=${linux_ms_tgt_platform//NA/vm-linux}

## one-offs
linux_ms_tgt_platform=${linux_ms_tgt_platform//Windows/vm-linux}
linux_ms_tgt_platform=${linux_ms_tgt_platform//infrastructure/infrastructure,vm-linux}
linux_ms_tgt_platform=${linux_ms_tgt_platform//ibiza/ibiza,vm-linux}
linux_ms_tgt_platform=${linux_ms_tgt_platform//command-line-interface/command-line-interface,vm-linux}
linux_ms_tgt_platform=${linux_ms_tgt_platform%d}

# windowses

windows_ms_tgt_platform=${windows_ms_tgt_platform// /}
windows_ms_tgt_platform=${windows_ms_tgt_platform///vm-windows}
windows_ms_tgt_platform=${windows_ms_tgt_platform//vm-multiple/vm-windows}
windows_ms_tgt_platform=${windows_ms_tgt_platform//vm-linux/vm-windows}
windows_ms_tgt_platform=${windows_ms_tgt_platform//na/vm-windows}
windows_ms_tgt_platform=${windows_ms_tgt_platform//NA/vm-windows}

## one-offs
windows_ms_tgt_platform=${windows_ms_tgt_platform//Windows/vm-windows}
windows_ms_tgt_platform=${windows_ms_tgt_platform//infrastructure/infrastructure,vm-windows}
windows_ms_tgt_platform=${windows_ms_tgt_platform//ibiza/ibiza,vm-windows}
windows_ms_tgt_platform=${windows_ms_tgt_platform//command-line-interface/command-line-interface,vm-windows}
windows_ms_tgt_platform=${windows_ms_tgt_platform%d}

# now, fix the metdata up
linux_ms_tgt_platform=$(echo "$linux_ms_tgt_platform" | gsed s/ms.tgt_pltfrm\.\*/ms.tgt_pltfrm=\"$linux_ms_tgt_platform\"/g)
windows_ms_tgt_platform=$(echo "$windows_ms_tgt_platform" | gsed s/ms.tgt_pltfrm\.\*/ms.tgt_pltfrm=\"$windows_ms_tgt_platform\"/g)

# echo "New linux extraction: $linux_ms_tgt_platform."
#echo "New windows extraction: $windows_ms_tgt_platform."

# Write the OS-specific metdata and fix it per wrapper file
WINDOWS_FILE_METADATA=$(echo "$FILE_METADATA" | gsed s/ms.tgt_pltfrm\.\*/ms.tgt_pltfrm=\"$windows_ms_tgt_platform\"/g)
LINUX_FILE_METADATA=$(echo "$FILE_METADATA" | gsed s/ms.tgt_pltfrm\.\*/ms.tgt_pltfrm=\"$linux_ms_tgt_platform\"/g)

quick_title=$(grep -P -m 1 "^#{1} *.*\w*?" $(find "$GITROOT" -name "$FILE" -type f))
#echo "title: $quick_title"

this_include=$(grep ".*AZURE.INCLUDE.*deployment-models.*" -m 1 $(find "$GITROOT" -name "$FILE" -type f))
#echo "the include for this file is: $this_include"

# grab the include line and excise it. if there's no include line, just process the file
# and log the fact that you need to fix the include.
short_body=""
if [[ "$(grep ".*AZURE.INCLUDE.*deployment-models.*" -m 1 $(find "$GITROOT" -name "$FILE" -type f) | wc -l)" -eq 1 ]]; then
    short_body=$(grep ".*AZURE.INCLUDE.*deployment-models.*" -A100000 -m 1 $(find "$GITROOT" -name "$FILE" -type f) | gsed -e 's/.*AZURE.INCLUDE.*deployment-models.*//g')
else 
    short_body=$(grep -P "^#{1} *.*\w*?" -A100000 -m 1 $(find "$GITROOT" -name "$FILE" -type f) | gsed -e 's/.*$title.*//g')
fi


# =========== file creation =================== #

# for general directory support
WRAPPER_FILE_Windows="$(dirname $(find "$GITROOT" -name "$FILE" -type f))/$NEWFILE"
WRAPPER_FILE_Linux="$(dirname $(find "$GITROOT" -name "$FILE" -type f))/$NEWFILE"

# for usage with link rewriting
link_target_linux=$NEWFILE
link_target_windows=$NEWFILE
link_target_linux=${link_target_linux//common/common-linux}
link_target_windows=${link_target_windows//common/common-windows}

echo "$link_target_linux"
echo "$link_target_windows"
#pause "do the links targets look right?"

WRAPPER_FILE_Linux=${WRAPPER_FILE_Linux//common/common-linux}
WRAPPER_FILE_Windows=${WRAPPER_FILE_Windows//common/common-windows}

echo "Linux : $WRAPPER_FILE_Linux"
echo "Windows: $WRAPPER_FILE_Windows"

# first, create branch for the rename:
temp_name=$(write_new_name)
temp_name=${temp_name%.md} 
#echo $temp_name
git checkout -b "$Assigned-$temp_name" release-vm-refactor

## first, move the file
echo "Moving \"$(find "$GITROOT" -name "$FILE" -type f)\" to \"../../includes/$NEWFILE\" in git..."

# check that they don't exist yet, or skip them.

if [ $(find "$GITROOT" -name "$WRAPPER_FILE_Linux" -type f | wc -l) -ne 0 ]; then
   echo "File '$(find "$GITROOT" -name "$FILE" -type f)' exists; skipping"
   #pause "$WRAPPER_FILE_Linux already exists but we're about to create it!."
   continue
fi

if [ $(find "$GITROOT" -name "$WRAPPER_FILE_Windows" -type f | wc -l) -ne 0 ]; then
   echo "File '$FILE' exists; skipping"
   #pause "$WRAPPER_FILE_Linux already exists but we're about to create it!."
   continue
fi

echo "$LINUX_FILE_METADATA" > $WRAPPER_FILE_Linux
echo "$WINDOWS_FILE_METADATA" > $WRAPPER_FILE_Windows

echo "" >> $WRAPPER_FILE_Linux
echo "" >> $WRAPPER_FILE_Windows

echo "$quick_title" >> $WRAPPER_FILE_Linux
echo "$quick_title" >> $WRAPPER_FILE_Windows

echo "" >> $WRAPPER_FILE_Linux
echo "" >> $WRAPPER_FILE_Windows

echo "$this_include" >> $WRAPPER_FILE_Linux
echo "$this_include" >> $WRAPPER_FILE_Windows

echo "" >> $WRAPPER_FILE_Linux
echo "" >> $WRAPPER_FILE_Windows

#echo "stem is $NEWFILESTEM"

echo "[AZURE.INCLUDE[$NEWFILESTEM](../../includes/$NEWFILE)]" >> $WRAPPER_FILE_Linux
echo "[AZURE.INCLUDE[$NEWFILESTEM](../../includes/$NEWFILE)]" >> $WRAPPER_FILE_Windows


### here we wrote the new include file; not yet in git
printf %s "$short_body" > $GITROOT/includes/$NEWFILE

## ADD the files so that git can track them.
echo "adding the new files"
git add -v "$WRAPPER_FILE_Linux" "$WRAPPER_FILE_Windows" "$GITROOT/includes/$NEWFILE"
git commit -m "committing the files: $WRAPPER_FILE_Linux $WRAPPER_FILE_Windows $GITROOT/includes/$NEWFILE"

#git status
#pause "a whole bunch of stuff just happened."
pause "go look at $GITROOT/includes/$NEWFILE"

# ================ Logging, redirects, and resx filese =============================
#echo $RedirectLOG
#echo $LOG
#echo $TOC_LOG
#echo $TOC_RESX_LOG

cleaned_quick_title=${quick_title//#/}
#cleaned_quick_title=${cleaned_quick_title# }

linux_article_json_resx_link="${link_target_linux%.md}"
linux_link_json_resx_link="Link_${linux_article_json_resx_link//-/_}"

windows_article_json_resx_link="${link_target_windows%.md}"
windows_link_json_resx_link="Link_${windows_article_json_resx_link//-/_}"

json_string_linux="\"$linux_link_json_resx_link\": \"article:$linux_article_json_resx_link\","
json_string_windows="\"$windows_link_json_resx_link\": \"article:$linux_article_json_resx_link\","

echo "$json_string_linux" # >> $TOC_LOG
echo "$json_string_windows" # >> $TOC_LOG

read -d '' resx_strings <<EOF
    <!-- for old file: $FILE   -->
    <data name="$linux_link_json_resx_link" xml:space="preserve">
        <value>$cleaned_quick_title</value>
    </data>
    <data name="$windows_link_json_resx_link" xml:space="preserve">
        <value>$cleaned_quick_title</value>
    </data>
EOF

echo "$resx_strings" # >> $TOC_RESX_LOG

# do the redirects bagsed on the $RedirectTarget

echo "${RedirectTarget%,}"

if [[ "$RedirectTarget" =~ .*Linux.* ]]; then
    docURLFragment="/documentation/articles"
    echo "<add key=\"$docURLFragment/$FILESTEM/\" value=\"$docURLFragment/$linux_article_json_resx_link/\" /> <!-- $(date +%D) -->"
    echo "<add key=\"$docURLFragment/$FILESTEM/\" value=\"$docURLFragment/$linux_article_json_resx_link/\" /> <!-- $(date +%D) -->" >> $RedirectLOG
else 
    docURLFragment="/documentation/articles"
    echo "<add key=\"$docURLFragment/$FILESTEM/\" value=\"$docURLFragment/$windows_article_json_resx_link/\" /> <!-- $(date +%D) -->"
    echo "<add key=\"$docURLFragment/$FILESTEM/\" value=\"$docURLFragment/$windows_article_json_resx_link/\" /> <!-- $(date +%D) -->" >> $RedirectLOG
fi

# moving to the bottom:
#git mv "$FILE" "$NEWFILE"
#ls $(dirname $(find "$GITROOT" -name "FILESTEM" -type d))
git rm -v "$(dirname $(find "$GITROOT" -name "$FILE" -type f))" 
git add -v "$GITROOT/includes/$NEWFILE"
#git commit -m "Renaming $FILE into $NEWFILE."
git status

# search for and rewire all inbound links 
echo "searching the repository for \"$FILE\" references..."

#pause "replacing $FILE with $link_target_linux"

find "$GITROOT" -name "*.md" -type f -exec grep -il "$FILE" {} + | xargs -I {} gsed -i'' -e s/"$FILE"/"$link_target_linux"/i {}
find "$GITROOT" -name "*.md" -type f -exec grep -il "$FILE" {} + | xargs -I {} gsed -i'' -e s/"$FILE"/"$link_target_windows"/i {}


# test for and move any media files associated with the original file
echo "Moving and relinking the media files...."

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
	       
#       pause "local new media link making path $local_SED_NEW_PATH"
        # TODO: Here's the problem. Warning: we are failing to git mv the media files
        # Resolution: on mac, and window, there's case-preserving but insensitive, which means there's no easy way to obtain
        # directories with capitalizations without already having them. BUT... 
        # as: ls media | grep -o '[^ ]*[A-Z][^ ]*'
        # shows us that only LOB and webLogic have caps in them in the articles/virtual-machines/media folder, we're just special casing those, above.
        # are we in the articles directory?
        echo "Here's the file: $(find $GITROOT -type f -name $FILE)"
        if [[ ! "$(find $GITROOT -type f -name $FILE)" =~ .*virtual-machines.* ]]; then
            pause "you figured it out... this shoudl NOT be in vms: $(find $GITROOT -type f -name $FILE)"
            articles_NEWMEDIAPATH="../includes/media/$NEWFILESTEM/$CURRENT_MEDIAFILE"
            # SED escaping
            articles_SED_NEW_PATH=${MEDIAPATH//\//\\/}
            pause "SED: new path for relinking: $articles_NEWMEDIAPATH"
            mkdir "$articles_NEWMEDIAPATH"
            pause "now moving media: ../includes/media/articles_$NEWFILESTEM/$CURRENT_MEDIAFILE"
            git mv -v "media/$FILESTEM/$CURRENT_MEDIAFILE" "../includes/media/articles_$NEWFILESTEM/$CURRENT_MEDIAFILE"            
            find "$GITROOT" -name "*.md" -type f -exec grep -il "$CURRENT_MEDIAPATH" {} + | xargs -I {} gsed -i'' -e s/"$SED_OLD_PATH"/"$SED_NEW_PATH"/i {}
            git ls-files -v -m "$GITROOT" "$CURRENT_MEDIAPATH" | xargs -I {} git add -v {}
            git commit -m "moving $CURRENT_MEDIAPATH"
        else
            # we are in the virtual-machines directory
            
            mkdir "../../includes/media/$NEWFILESTEM"
            # again, moving creates a commit. Want to break this into a cp and an rm, which is what git does anyway.
            # BUT: there's no "git cp"
            #git mv "media/$FILESTEM/$CURRENT_MEDIAFILE" "media/$NEWFILESTEM/$CURRENT_MEDIAFILE"
            pause "moving \"media/$FILESTEM/$CURRENT_MEDIAFILE\" to \"../../includes/media/$NEWFILESTEM/$CURRENT_MEDIAFILE\""
            git mv -v "media/$FILESTEM/$CURRENT_MEDIAFILE" "../../includes/media/$NEWFILESTEM/$CURRENT_MEDIAFILE"
            #git rm "media/$FILESTEM/$CURRENT_MEDIAFILE" 

            # rewrite inbound media links from the moved media file.
            pause "SED: new path for relinking: $SED_NEW_PATH"
            find "$GITROOT" -name "*.md" -type f -exec grep -il "$CURRENT_MEDIAPATH" {} + | xargs -I {} gsed -i'' -e s/"$SED_OLD_PATH"/"$SED_NEW_PATH"/i {}
            git ls-files -m "$GITROOT" "$CURRENT_MEDIAPATH" | xargs -I {} git add {}
            
        fi
 
        # You can add, but you may NOT commit    
        git ls-files -m "$GITROOT" $NEWFILE | xargs -I {} git add {}
        #git commit -m "Moving $CURRENT_MEDIAPATH to $NEWMEDIAPATH"
    done

fi

# clean up the gsed modifications
find $(git rev-parse --show-toplevel) -name "*.md-e" -type f -exec rm {} +
#Do the committing for the files you changed. Maybe you can't avoid it.
# Because the include is a brand new file, we just add it along with everything at once
git rm -f "$(dirname $(find "$GITROOT" -name "$FILE" -type f))/$FILE"
git ls-files -m "$GITROOT" *.md | xargs -I {} git add {}
#git add $NEWFILE

git commit -m "Renaming $FILE into $NEWFILE."
git status

#git reset --hard release-vm-refactor

# Do the push and PR creation:

echo "pushing to $Assigned-$temp_name:$Assigned-$temp_name"
#git push -v squillace "$Assigned-$temp_name":"$Assigned-$temp_name"
#echo "$(timestamp): $(hub pull-request -m "[$Assigned]:[$NEWFILESTEM] Tagcheck: \"$tags\"" -b squillace:vm-refactor-staging -h squillace:$Assigned-$temp_name $(git rev-parse HEAD))" >> $LOG 
#echo "$timestamp: $(hub pull-request -m "[$Assigned]:[$NEWFILESTEM] Tagcheck: \"$tags\"" -b squillace:vm-refactor-staging -h #squillace:$Assigned-$temp_name $(git rev-parse HEAD)))" >> $LOG 
#git reset --hard vm-refactor-staging
git checkout vm-refactor-staging
#git status





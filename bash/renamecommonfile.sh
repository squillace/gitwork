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

FILE_METADATA=$(sed -n '/<properties/,/ms.author.*/p' $FILE)
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

quick_title=$(grep -P "^#[ ]{1}.*\w*.*" $FILE)
echo "title: $quick_title"

this_include=$(grep ".*AZURE.INCLUDE.*deployment-models.*" -m 1 $FILE)
echo "the include for this file is: $this_include"
# grab the include line and excise it. if there's no include line, just process the file
# and log the fact that you need to fix the include.
short_body=""
if [[ "$(grep ".*AZURE.INCLUDE.*deployment-models.*" -m 1 $FILE | wc -l)" -eq 1 ]]; then
    short_body=$(grep ".*AZURE.INCLUDE.*deployment-models.*" -A100000 -m 1 $FILE | gsed -e 's/.*AZURE.INCLUDE.*deployment-models.*//g')
else 
    short_body=$(grep -P "^#[ ]{1}.*\w*.*" -A100000 -m 1 $FILE | gsed -e 's/.*$title.*//g')
fi
#printf %s $body
#$(printf %s "$body" | tail -n +3)

#include_line_number=$(grep  -n ".*AZURE.INCLUDE.*deployment-models.*" -m 1 $FILE | cut -c 1-2)

#echo "$include_line_number"
#pause "that was the include line number"

WRAPPER_FILE_Windows=$NEWFILE
WRAPPER_FILE_Linux=$NEWFILE

WRAPPER_FILE_Linux=${WRAPPER_FILE_Linux//common/common-linux}
WRAPPER_FILE_Windows=${WRAPPER_FILE_Windows//common/common-windows}

echo "$WRAPPER_FILE_Linux"
echo "$WRAPPER_FILE_Windows"


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

echo "stem is $NEWFILESTEM"

echo "[AZURE.INCLUDE[$NEWFILESTEM](../../includes/$NEWFILE)]" >> $WRAPPER_FILE_Linux
echo "[AZURE.INCLUDE[$NEWFILESTEM](../../includes/$NEWFILE)]" >> $WRAPPER_FILE_Windows

printf %s "$short_body" > $GITROOT/includes/$NEWFILE

# do the logging work for redirects and to the new files created for toc.
echo $RedirectLOG
echo $LOG
echo $TOC_LOG
echo $TOC_RESX_LOG

cleaned_quick_title=${quick_title//#/}
cleaned_quick_title=${cleaned_quick_title# }

json_string_linux="\"Link_$WRAPPER_FILE_Linux\": \"article:${WRAPPER_FILE_Linux%.md}\","
json_string_windows="\"Link_$WRAPPER_FILE_Windows\": \"article:${WRAPPER_FILE_Windows%.md}\","

echo "$json_string_linux" >> $TOC_LOG
echo "$json_string_windows" >> $TOC_LOG

read -d '' resx_strings <<EOF
    <data name="$WRAPPER_FILE_Linux" xml:space="preserve">
        <value>"$cleaned_quick_title"</value>
    </data>
    <data name="$WRAPPER_FILE_Windows" xml:space="preserve">
        <value>"$cleaned_quick_title"</value>
    </data>
EOF

echo "$resx_strings" >> $TOC_RESX_LOG


# do the redirects based on the $RedirectTarget

echo "$RedirectTarget"

# START HERE

pause "$RedirectTarget"
    docURLFragment="/documentation/articles"
    echo "<add key=\"$docURLFragment/$FILESTEM/\" value=\"$docURLFragment/${WRAPPER_FILE_Linux%.md}/\" /> <!-- $(date +%D) -->" >> $RedirectLOG
    docURLFragment="/documentation/articles"
    echo "<add key=\"$docURLFragment/$FILESTEM/\" value=\"$docURLFragment/${WRAPPER_FILE_Windows%.md}/\" /> <!-- $(date +%D) -->" >> $RedirectLOG


# first, create branch for the rename:
temp_name=$(write_new_name)
temp_name=${temp_name%.md} 
echo $temp_name
#git checkout -b "$Assigned-$temp_name" release-vm-refactor

## first, move the file
echo "Moving \"$FILE\" to \"$NEWFILE\" in git..."

# moving to the bottom:
#git mv "$FILE" "$NEWFILE"
    
# search for and rewire all inbound links 
echo "searching the repository for \"/$FILE\" references..."

find "$GITROOT" -name "*.md" -type f -exec grep -il "$FILE" {} + | xargs -I {} gsed -i'' -e s/"$FILE"/"$WRAPPER_FILE_Linux"/i {}
find "$GITROOT" -name "*.md" -type f -exec grep -il "$FILE" {} + | xargs -I {} gsed -i'' -e s/"$FILE"/"$WRAPPER_FILE_Windows"/i {}

 continue 
#git ls-files -m "$GITROOT" *.md | xargs -I {} git add {}
#git add $NEWFILE
#git commit -m "Renaming $FILE into $NEWFILE."
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
        # again, moving creates a commit. Want to break this into a cp and an rm, which is what git does anyway.
        #git mv "media/$FILESTEM/$CURRENT_MEDIAFILE" "media/$NEWFILESTEM/$CURRENT_MEDIAFILE"
        git cp "media/$FILESTEM/$CURRENT_MEDIAFILE" "media/$NEWFILESTEM/$CURRENT_MEDIAFILE"
        git rm "media/$FILESTEM/$CURRENT_MEDIAFILE" 

        # rewrite inbound media links from the moved media file.
        find "$GITROOT" -name "*.md" -type f -exec grep -il "$CURRENT_MEDIAPATH" {} + | xargs -I {} gsed -i'' -e s/"$SED_OLD_PATH"/"$SED_NEW_PATH"/i {}
	    
        # You can add, but you may NOT commit    
        git ls-files -m "$GITROOT" *.md | xargs -I {} git add {}
        #git commit -m "Moving $CURRENT_MEDIAPATH to $NEWMEDIAPATH"
    done

fi


# clean up the sed modifications
find $(git rev-parse --show-toplevel) -name "*.md-e" -type f -exec rm {} +

#Do the committing for the files you changed. Maybe you can't avoid it.
#git mv "$FILE" "$NEWFILE"
#git cp "$FILE" "$NEWFILE"
#git rm "$FILE" 

# Do the push and PR creation:

#echo "pushing to $Assigned-$temp_name:$Assigned-$temp_name"
#pause "Assigned: $Assigned"
#$(git push -v squillace "$Assigned-$temp_name":"$Assigned-$temp_name")
#echo "$(timestamp): $(hub pull-request -m "[$Assigned]:[$NEWFILESTEM] Tagcheck: \"$tags\"" -b squillace:vm-refactor-staging -h #squillace:$Assigned-$temp_name $(git rev-parse HEAD))" >> $LOG 

#hub pull-request -m "trying one more time" -b squillace:release-vm-refactor -h squillace:vm-refactor-staging $(git rev-parse HEAD)

#git checkout vm-refactor-staging
#git status




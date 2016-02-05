#!/bin/bash
# set -x
# establish the root of the git directory
GITROOT=$(git rev-parse --show-toplevel)

# logging configuration
LOG=/var/log/readcsv.log
sudo chown -R rasquill /var/log/

timestamp() {
  date +"%T"
}

# for testing, pauses with a message until ENTER is pressed
function pause(){
   read -p "$*" input </dev/tty
}

# Extracts the tags string from a file and cleans it.
function get_tags() {
    #echo $1
    local FILEPATH=$(find "$GITROOT" -name "$1" -type f)
    #echo "file is $1"
    #echo "gitroot is $GITROOT"
    #echo "getting complete path is "
    #find "$GITROOT" -name "$1" -type f
    #echo $(grep -Pohr "(?<=tags=\").*" $FILEPATH | sed s/\".*//g)
    eval "$2='$(grep -Pohr "(?<=tags=\").*" $FILEPATH | sed s/\".*//g)'"
}

# Extracts the topic title directly from the files
function get_Title(){
    local FILEPATH=$(find "$GITROOT" -name "$1" -type f)
#    echo "File argument is $1"
#    echo "gitroot is $GITROOT"
#    echo "getting complete path is $(find "$GITROOT" -name "$1" -type f)"
    
    echo "\"$(grep -Pohr -m 1 "#+.*" $FILEPATH | sed "s/# *//g" | sed "s/<.*>//g")\""
}

# Determines whether something is BOTH 
function asm_arm_or_both(){
    infix=""
    if [[ "$1" =~ .*azure-resource-manager.* && "$1" =~ .*azure-resource-manager.* ]]; then
        echo "-" 
    else 
        if [[ "$1" =~ .*azure-resource-manager.* ]]; then
            echo "arm-" 
        else 
            if [[ "$1" =~ .*azure-service-management.* ]]; then
                echo "asm-" 
            fi
        
        fi    
    fi
}

# replaces underscores with hyphens
function norm_hypens(){
    echo $1 | sed s/_/-/g 
}

# takes tags, newnameslug, and OS to construct new name
function build_new_name(){
    local new_name=""
    
    echo "vms-linux-$(asm_arm_or_both $1)$(norm_hypens $2).md" | sed s/--/-/g
}

function no_tags()
{
            echo ""
            echo "=================================================================================================================" >> $1
            echo "$(timestamp): $contentID.md, line $COUNT =================>>>>>>>>>>> Doesn't have any tag for deployment" >> $1
            echo "$(timestamp): Assigned: $Assigned"  >> $1
            echo "$(timestamp): Title: $(get_Title $contentID.md)" >> $1
            echo "$(timestamp): URL: $URL" >> $1
            echo "$(timestamp): contentID: $contentID" >> $1
            echo "$(timestamp): Author: $Author" >> $1
            echo "$(timestamp): Tags: $tags" >> $1
            echo "$(timestamp): MSTgtPltfrm: $MSTgtPltfrm" >> $1
            echo "$(timestamp): NewNameSlug: $(norm_hypens $NewNameSlug)" >> $1
            echo "$(timestamp): Include: $Include" >> $1
            echo "$(timestamp): Windows: $Windows" >> $1
            echo "$(timestamp): Linux: $Linux" >> $1
            echo "$(timestamp): RedirectTarget: $RedirectTarget" >> $1
            
            
}

echo "Log file is: $LOG."
echo "Starting run: $(date)." >> $LOG

let COUNT=0
tags=""
while IFS=, read Assigned URL contentID Author MSTgtPltfrm NewNameSlug Include Windows Linux RedirectTarget
do
    ((COUNT++))
    echo "Reading line: $COUNT"
    if [ "$COUNT" -eq 1 ]; then
        echo "$timestamp: Header line read."
        continue

    fi


    get_tags $contentID.md tags
    
    if [[ ! "$tags" =~ .*azure-resource-manager.* && ! "$tags" =~ .*azure-service-management.* ]]; then
        
        echo "hey, we don't have either tag here!!!!!!!!!!!!!!!"
        if [[ "$NewNameSlug" =~ .*asm.* ]]; then
            echo "BUT is does have asm in $NewNameSlug..."
        fi
        # log the fact that we can't do anything with this file and move on
        no_tags $LOG $Assigned $URL $contentID.md $Author MSTgtPltfrm $(norm_hypens $NewNameSlug) $Include $Windows $Linux $RedirectTarget
        pause "Press ENTER to continue..."   
        continue
    fi
    
    
    echo "Assigned: $Assigned"
    echo "Title: $(get_Title $contentID.md)"
    echo "URL: $URL"
    echo "contentID: $contentID"
    echo "Author: $Author"
    echo "Tags: $tags"
    echo "MSTgtPltfrm: $MSTgtPltfrm"
    echo "NewNameSlug: $(norm_hypens $NewNameSlug)"
    echo "Include: $Include"
    echo "Windows: $Windows"
    echo "Linux: $Linux"
    echo "RedirectTarget: $RedirectTarget"
    echo "newname: $(build_new_name $tags $NewNameSlug)"
    
    echo ""       

    pause "Press ENTER to continue..."   
    
    #source ~/workspace/gitwork/bash/renamefile.sh $contentID.md $(build_new_name $tags $NewNameSlug)
    #find $(git rev-parse --show-toplevel) -name "*.md-e" -type f -exec rm {} +
done < $1


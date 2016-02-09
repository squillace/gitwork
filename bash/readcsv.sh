#!/bin/bash


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
    eval "$2='$(grep -Pohr "(?<=tags=\").*(?=\"/>)" $FILEPATH )'"
}

# Extracts the topic title directly from the files
function get_Title(){
    local FILEPATH=$(find "$GITROOT" -name "$1" -type f)
#    echo "File argument is $1"
#    echo "gitroot is $GITROOT"
#    echo "getting complete path is $(find "$GITROOT" -name "$1" -type f)"

    echo "\"$(grep -Pohr -m 1 "(?<=^#).*" $FILEPATH | sed "s/^ *//g" | sed "s/<.*>//g")\""
}

# Determines whether something is BOTH
function asm_arm_or_both(){
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

#        if [[ "$NewNameSlug" =~ .*asm.* ]]; then
#            echo "BUT is does have asm in $NewNameSlug..."
#        fi


function windows_linux_both(){

    if [[ "$Windows" =~ .*_.* ]]; then
             echo "FIRST: It's Windows!!!"
    elif [[ "$contentID" =~ .*windows.* || "$MSTgtPltfrm" =~ .*windows.* || "$NewNameSlug" =~ .*windows.* ]]; then
            echo "SECOND PASS: It's STILL Windows!!!"
            pause "second pass...."
    elif [[ "$Linux" =~ .*_.* ]]; then
            echo "FIRST: It's Linux!!!"
    elif [[ "$contentID" =~ .*linux.* || "$MSTgtPltfrm" =~ .*linux.* || "$NewNameSlug" =~ .*linux.* ]]; then
            echo "SECOND PASS: It's STILL Linux!!!"
            pause "second pass...."
    fi
}

# replaces underscores with hyphens
function norm_hypens(){
    echo $1 | sed s/_/-/g
}

# takes tags, newnameslug, and OS to construct new name
## 1. remove any "virtual-machines-" strings.
## 2. remove any -arm- and set "arm" flag
## 3. remove any -asm- and set "asm" flag
## 4. remove any -windows- set "windows" flag
## 5. remove any -linux- and set "linux" flag
## 6. take the stem and write: "virtual-machines"-windows|linux-arm|asm-remaining slug
nonVirtualMachinesCount=0
function build_new_name(){
#    set -x
    local new_name=""
    local current_name="$NewNameSlug"
    #echo "Current name is : $current_name"
    current_name=${current_name//_/-}
    
    # remove virtual-machine[s] and clean hyphens
    new_name=${current_name//virtual-machines/}
    new_name=${new_name//virtual-machine/}
    new_name=${new_name//-vms-/}
    new_name=${new_name//-vm-/}
    new_name=${new_name#vms-}
    new_name=${new_name#vm-}
    new_name=${new_name%-vms}
    new_name=${new_name%-vm}
    new_name=${new_name%-}
    new_name=${new_name#-}
    
    # remove linux and clean hyphens
    new_name=${new_name//linux/}
    new_name=${new_name%-}
    new_name=${new_name#-}
    
    # remove windows and clean hyphens
    new_name=${new_name//windows-server/}
    new_name=${new_name//windows/}
    new_name=${new_name%-}
    new_name=${new_name#-}

    # remove asm and clean hyphens
    new_name=${new_name//-asm-/}
    new_name=${new_name%-asm}
    new_name=${new_name#asm-}
    
    # remove arm and clean hyphens
    new_name=${new_name//-arm-/}
    new_name=${new_name%-arm}
    new_name=${new_name#-}
    new_name=${new_name%-}
    
    new_name=${new_name//--/-}
    
    #echo "New name stem is : $new_name"
    
    #pause "...."
    local final_name="virtual-machines-$1-$(asm_arm_or_both $tags)$new_name.md" 
    echo ${final_name//--/-}
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




#========================================================================================================
#========================================================================================================
#========================================================================================================

# set -x
# establish the root of the git directory
GITROOT=$(git rev-parse --show-toplevel)

# logging configuration
LOG=/var/log/readcsv.log
OUTPUT=/var/log/output.log
sudo chown -R rasquill /var/log/
echo "Log file is: $LOG."
echo "Starting run: $(date)." >> $LOG

let COUNT=0
tags=""
while IFS=, read Assigned URL contentID Author MSTgtPltfrm NewNameSlug Include Windows Linux RedirectTarget
do
    ((COUNT++))
    echo "Reading line: $COUNT"
    # skip the header in the CSV file
    if [ "$COUNT" -eq 1 ]; then
        echo "$timestamp: Header line read."
        continue
    fi

    # if you can't find the file in the repo, log it and continue on.
    if [ ! -f $(find "$GITROOT" -name "$contentID.md" -type f) ]; then
        echo "$(timestamp): The File '$(find "$GITROOT" -name "$contentID.md" -type f)' Does Not Exist" >> $LOG
        continue 
    fi


#    windows_linux_both

    get_tags $contentID.md tags
    
   
    # Log the toc stuff
#    This is the format of the lines for the .resx:
 
#    <data name="Link_file_name" xml:space="preserve">
#        <value>My title for left-nav</value>
#    </data>
    
#    This is the format for the lines for the .json:
    
#    "Link_file_name": "article:file-name",
    

# create the redirect string

#docURLFragment="/documentation/articles"
#echo "<add key=\"$docURLFragment/$FILESTEM/\" value=\"$docURLFragment/$NEWFILESTEM/\" /> <!-- $(date +%D) -->" >> $RedirectLOG

    if [[ ! "$Assigned" == "davidmu" ]]; then 
        echo "It's not David"
        continue
    fi
    
    if [[ ! "$tags" =~ .*azure-resource-manager.* && ! "$tags" =~ .*azure-service-management.* ]]; then

        echo "hey, we don't have either tag here!!!!!!!!!!!!!!!"
        if [[ "$NewNameSlug" =~ .*asm.* ]]; then
            echo "BUT is does have asm in $NewNameSlug... i"
        fi
        # log the fact that we can't do anything with this file and move on
        no_tags $LOG $Assigned $URL $contentID.md $Author MSTgtPltfrm $(norm_hypens $NewNameSlug) $Include $Windows $Linux $RedirectTarget
        #pause "Press ENTER to continue..."
        #continue
    fi
    

    
    if [[ "$Include" =~ .*_.* ]]; then
        echo "It's an include file....so here we pass the variable to the include script using \"source\""
        new_topic_name=$(build_new_name "common")
    elif [[ "$Windows" =~ .*_.* ]]; then
        echo "It's a windows target, so move into the rename windows process..."
        new_topic_name=$(build_new_name "windows")
        source ~/workspace/gitwork/bash/renamefile.sh $contentID.md $new_topic_name

    elif [[ "$Linux" =~ .*_.* ]]; then
        echo "It's a linux target, so move into the rename linux process..."
        new_topic_name=$(build_new_name "linux")
        source ~/workspace/gitwork/bash/renamefile.sh $contentID.md $new_topic_name
    else
        echo "$(timestamp): Can't detect what OS is the intended target for line $COUNT: $contentID" >> $LOG
        #no_tags $LOG $Assigned $URL $contentID.md $Author MSTgtPltfrm $(norm_hypens $NewNameSlug) $Include $Windows $Linux $RedirectTarget
    fi
    
    # for testing, only run through errors.
#    continue

#    write_filename_logs $new_topic_name

     #set -x
    echo "Assigned: $Assigned"
    echo "Title: $(get_Title $contentID.md)"
    echo "URL: $URL"
    echo "contentID: $contentID"
    echo "Author: $Author"
    echo "Tags: $tags"
    echo "MSTgtPltfrm: $MSTgtPltfrm"
    echo "NewNameSlug: $NewNameSlug"
    echo "Include: $Include"
    echo "Windows: $Windows"
    echo "Linux: $Linux"
    echo "RedirectTarget: $RedirectTarget"
    echo "New topic name: $new_topic_name"

    echo ""

    pause "Press ENTER to continue..."

    #source ~/workspace/gitwork/bash/renamefile.sh $contentID.md $new_topic_name
    #find $(git rev-parse --show-toplevel) -name "*.md-e" -type f -exec rm {} +

done < $1


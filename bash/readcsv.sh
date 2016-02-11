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

    # for the record: grep -Pohr -m 1 "(?<=^#)[ ].*\w*" $FILEPATH 
    # grab the first instance of a line that starts with '#' and any spaces that follow.
    # grab the strings in that line
    # remove any leading spaces: sed "s/^ *//g"
    # remove any HTML elements in the title string: sed "s/<.*>//g"
    # remove CR : tr -d '\015'
    # remove LF
    # remove any trailing #
    eval "$2='$(grep -Pohr -m 1 "(?<=^#)[ ].*\w*" $FILEPATH | sed "s/^ *//g" | sed "s/<.*>//g" | tr -d '\015' | tr -d '\012'| tr -d '#')'"
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

function build_new_name(){
#    set -x
    local new_name=""
    local current_name="$NewNameSlug"
    #echo "Current name is : $current_name"
    # replace underscores with hyphens
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
    # must not remove swarm or farm
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

## remove after testing
function write_new_name(){
    #echo $1
    local new_name=""
    local current_name="$NewNameSlug"
    #echo "Current name is : \"$current_name\""
    #echo "Name slug is: \"$NewNameSlug\""
    current_name=${current_name//_/-}
    
    # remove virtual-machine[s] and clean hyphens
    new_name=${current_name//virtual-machines/}
    new_name=${new_name//virtual-machine/}
    new_name=${new_name//-vms-/}
    new_name=${new_name//-vm-/}
    new_name=${new_name#vms-}
    new_name=${new_name#vm-}
    #new_name=${new_name%-vms}
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
    # must not remove swarm or farm or armcompare
    new_name=${new_name//-arm-/}
    new_name=${new_name%-arm}
    new_name=${new_name#arm-}
    new_name=${new_name%-}
    
    new_name=${new_name//--/-}
    new_name=${new_name// /}
    
    #echo "after modifications the Current name is : $new_name"

    
    ## add the deployment information
    
    if [[ "$NewNameSlug" =~ .*asm.* && ! "$NewNameSlug" =~ .*arm.* && ! "$NewNameSlug" =~ .*farm.* && ! "$NewNameSlug" =~ .*swarm.* ]]; then
        new_name=${new_name//$new_name/classic-$new_name}
    elif [[ "$NewNameSlug" =~ .*asm.* && ! "$NewNameSlug" =~ .*arm.* && ! "$NewNameSlug" =~ .*farm.* && ! "$NewNameSlug" =~ .*swarm.* ]]; then
        new_name=${new_name//$new_name/classic-$new_name}
    elif [[ "$NewNameSlug" =~ .*asm.* && ! "$NewNameSlug" =~ .*arm.* && ! "$NewNameSlug" =~ .*farm.* && ! "$NewNameSlug" =~ .*swarm.* ]]; then
        new_name=${new_name//$new_name/classic-$new_name}
     else       
            echo "$(timestamp): Can't detect what deployment is the intended target for line $COUNT: $contentID" >> $LOG
            #no_tags $LOG $Assigned $URL $contentID.md $Author MSTgtPltfrm $(norm_hypens $NewNameSlug) $Include $Windows $Linux $RedirectTarget
     fi        
            
    ## add the os information
      
    if [[ "$Include" =~ .*_.* ]]; then
        #echo "It's an include file....so here we pass the variable to the include script using \"source\""
        new_name=${new_name//$new_name/common-$new_name}
    elif [[ "$Windows" =~ .*_.* ]]; then
        #echo "It's a windows target, so move into the rename windows process..."
        new_name=${new_name//$new_name/windows-$new_name}
        # source ~/workspace/gitwork/bash/renamefile.sh $contentID.md $new_topic_name

    elif [[ "$Linux" =~ .*_.* ]]; then
        #echo "It's a linux target, so move into the rename linux process..."
        new_name=${new_name//$new_name/linux-$new_name}

        # source ~/workspace/gitwork/bash/renamefile.sh $contentID.md $new_topic_name
        # special casing this one file
        if [[ "$NewNameSlug" =~ .*ssh_from_linux.* ]]; then
            new_name=${new_name//from/from-linux}
        elif [[ "$NewNameSlug" =~ .*ssh_from_windows.* ]]; then
            # special casing this one file
            new_name=${new_name//from/from-windows}
        fi

    else
        echo "$(timestamp): Can't detect what OS is the intended target for line $COUNT: $contentID" >> $LOG
        #no_tags $LOG $Assigned $URL $contentID.md $Author MSTgtPltfrm $(norm_hypens $NewNameSlug) $Include $Windows $Linux $RedirectTarget
    fi    
    
    #pause "....$1"
    local final_name="virtual-machines-$new_name.md" 
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
#=================== Main portion of the program +++++===================================================
#========================================================================================================

# set -x
# establish the root of the git directory
GITROOT=$(git rev-parse --show-toplevel)

# logging configuration
LOG=/var/log/readcsv.log
RedirectLOG=~/redirects.log
OUTPUT=/var/log/output.log
sudo chown -R rasquill /var/log/
#echo "Log file is: $LOG."
echo "Starting run: $(date)." >> $LOG

let COUNT=0
tags=""
title=""
temp_name=""
while IFS=, read Assigned URL contentID Author MSTgtPltfrm NewNameSlug Include Windows Linux RedirectTarget
do

    ((COUNT++))
    echo "Reading line: $COUNT"
    # skip the header in the CSV file
    if [ "$COUNT" -eq 1 ]; then
        #echo "$timestamp: Header line read."
        continue
    fi

    # if you can't find the file in the repo, log it and continue on.
    if [ ! -f $(find "$GITROOT" -name "$contentID.md" -type f) ]; then
        echo "$(timestamp): The File '$(find "$GITROOT" -name "$contentID.md" -type f)' Does Not Exist" >> $LOG
        continue 
    fi
    
# debugging section

    if [[ ! "$Assigned" == "davidmu" ]]; then 
        #echo "It's not David"
        continue
    fi

    #echo "$contentID -- checking for ssh-from"
#   if [[ "$NewNameSlug" =~ .*ssh_from.* ]]; then
#        echo "Here we are..."
#    else    
#        continue
#    fi
    
# end debugging section

#    windows_linux_both

    get_tags $contentID.md tags
    get_Title $contentID.md title
    echo "Tags are read as: $tags"
    # clean the title
    title=${title% }
    title=${title# }
    
    
    # Log the toc stuff
#    This is the format of the lines for the .resx:
 
#    <data name="Link_file_name" xml:space="preserve">
#        <value>My title for left-nav</value>
#    </data>
    
#    This is the format for the lines for the .json:
    
#    "Link_file_name": "article:file-name",
    

# create the redirect string

docURLFragment="/documentation/articles"
echo "<add key=\"$docURLFragment/$FILESTEM/\" value=\"$docURLFragment/$NEWFILESTEM/\" /> <!-- $(date +%D) -->" >> $RedirectLOG

    if [[ "$Include" =~ .*_.* ]]; then
        #echo "It's an include file....so here we pass the variable to the include script using \"source\""
        new_topic_name=$(write_new_name)
        source ~/workspace/gitwork/bash/renamecommonfile.sh $contentID.md $new_topic_name
    elif [[ "$Windows" =~ .*_.* ]]; then
        #echo "It's a windows target, so move into the rename windows process..."
        new_topic_name=$(write_new_name)
        #source ~/workspace/gitwork/bash/renamefile.sh $contentID.md $new_topic_name

    elif [[ "$Linux" =~ .*_.* ]]; then
       #echo "It's a linux target, so move into the rename linux process..."
        new_topic_name=$(write_new_name)
        #source ~/workspace/gitwork/bash/renamefile.sh $contentID.md $new_topic_name
    else
        echo "$(timestamp): Can't detect what OS is the intended target for line $COUNT: $contentID" >> $LOG
        #no_tags $LOG $Assigned $URL $contentID.md $Author MSTgtPltfrm $(norm_hypens $NewNameSlug) $Include $Windows $Linux $RedirectTarget
    fi
 
 #   write_filename_logs $new_topic_name

	echo "Assigned: $Assigned"
    echo "Title for $contentID.md: $title"
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

    #pause "Here we've done a PR..."

    #source ~/workspace/gitwork/bash/renamefile.sh $contentID.md $new_topic_name
    #find $(git rev-parse --show-toplevel) -name "*.md-e" -type f -exec rm {} +

done < $1


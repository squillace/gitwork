#!/bin/bash

GITROOT=$(git rev-parse --show-toplevel)

function pause(){
   read -p "$*" input </dev/tty
}

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

function isAsm(){
    if [[ "$1" =~ .*azure-service-management.* ]]; then
        echo "asm"
    fi
}

function isArm(){
    if [[ "$1" =~ .*azure-resource-manager.* ]]; then
        echo "arm" 
    fi
}

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

function norm_hypens(){
    echo $1 | sed s/_/-/g 
}

# takes tags, newnameslug, and OS to construct new name
function build_new_name(){
    echo "vms-linux-$(asm_arm_or_both $1)$(norm_hypens $2).md" | sed s/--/-/g
    
}


let COUNT=0
tags=""
while IFS=, read Assigned Title URL contentID Author MSTgtPltfrm NewNameSlug Include Windows Linux RedirectTarget
do
    ((COUNT++))
#    echo "$COUNT"
    if [ "$COUNT" -eq 1 ]; then
        continue
    fi
    

    get_tags $contentID.md tags
    
    
    echo "Assigned: $Assigned"
    echo "Title: $Title"
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
done < $1


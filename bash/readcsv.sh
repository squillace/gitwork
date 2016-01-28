#!/bin/bash

GITROOT=$(git rev-parse --show-toplevel)

function pause(){
   read -p "$*" input </dev/tty
}

function get_tags() {
    echo $1
    find "$GITROOT" -name "$1" -type f -exec grep -ol "$FILE" {} +
    eval "$2='foo bar rab oof'"
}

function isAsm(){
    if [[ "$1" =~ .*azure-service-management.* ]]; then
        eval "$2='true'" 
    fi
}

function isArm(){
    if [[ "$1" =~ .*azure-resource-manager.* ]]; then
        eval "$2='true'" 
    fi
}

function asm_arm_or_both(){
    
    case "" in 
        *foo*)
        echo "asm"
        ;;
    esac
    
}

string=""
isAsm "azure-service-management,azure-resource-manager" string
echo "$string"

string=""
isArm "azure-service-management,azure-resource-manager" string
echo "$string"


return_var=''
get_tags virtual-machines-linux-tutorial.md return_var
echo $return_var

let COUNT=0
while IFS=, read Assigned Title URL contentID Author MSTgtPltfrm NewNameSlug Include Windows Linux RedirectTarget
do
    ((COUNT++))
#    echo "$COUNT"
    if [ "$COUNT" -eq 1 ]; then
        continue
    fi
    
    return_var=''
    get_tags virtual-machines-linux-tutorial.md return_var
    
    
    echo "Assigned: $Assigned"
    echo "Title: $Title"
    echo "URL: $URL"
    echo "contentID: $contentID"
    echo "Author: $Author"
    echo "Tags: $(get_tags $contentID.md return_var)"
    echo "MSTgtPltfrm: $MSTgtPltfrm"
    echo "NewNameSlug: $NewNameSlug"
    echo "Include: $Include"
    echo "Windows: $Windows"
    echo "Linux: $Linux"
    echo "RedirectTarget: $RedirectTarget"
    echo ""
    
    
    
    pause "Press ENTER to continue..."   
done < $1


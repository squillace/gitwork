#!/bin/bash

# for testing, pauses with a message until ENTER is pressed
function pause(){
   read -p "$*" input </dev/tty
}

# creates a heading for the toc
function create_heading(){
   echo "# [$1]($2)" >> $2
}

if [ $# -ne 2 ]; then
    echo "there are not two file targets"
    exit 1
elif [ $(ls $1 | wc -l) -eq 0 ]; then
    echo "Can't find the input file $1."
    exit 1
elif [[ ! -d $2 ]]; then
    echo "hey, the directory doesn't exist!!"
fi

echo "Import source file: $1"
echo "Export file target: $2"
SOURCE_FILE="$1"
SOURCE_RESX_FILE=""
TARGET_FILE="$2/TOC.md"

heads=$(cat $SOURCE_FILE | jq -r '. | keys[]')
# echo "$heads"

for H1 in $heads
    do
    xpath="//data[@name=\""$H1\""]/value/text()"
    title=$(xmllint --xpath $xpath  ~/workspace/acom/code/acom/ACOM.Resources/Shared/Lefties/virtual-machines-linux.resx)
	echo "# [$title]" >> $TARGET_FILE
    subheads=$(cat $SOURCE_FILE | jq -r ".$H1 | keys[]")
    #echo "$subheads"
    for H2 in $subheads
        do
            xpath="//data[@name=\""$H2\""]/value/text()"
            subtitle=$(xmllint --xpath $xpath  ~/workspace/acom/code/acom/ACOM.Resources/Shared/Lefties/virtual-machines-linux.resx)
            article_string=$(cat $SOURCE_FILE | jq -r ".$H1[\"$H2\"]")
            article_string=${article_string//acom:/https://azure.microsoft.com}
            article_string=${article_string//msdn:/https://msdn.microsoft.com/en-us/library/azure/}
            if [[ "$article_string" =~ article:.* ]];then
                article_string=${article_string//article:/}
                article_string="$article_string".md
            fi
            echo "## [$subtitle]($article_string)" >> $TARGET_FILE
    done
done
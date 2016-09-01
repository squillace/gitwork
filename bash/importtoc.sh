#!/bin/bash

# for testing, pauses with a message until ENTER is pressed
function pause(){
   read -p "$*" input </dev/tty
}

function create_toc(){
#    set -x
    if [ $# -ne 1 ]; then
        echo "an input files is required."
        exit 1
    fi

    SOURCE_FILE=~/workspace/acom/code/acom/Acom.Json/Data/Lefties/$1.contentmap.json
    SOURCE_RESX_FILE=~/workspace/acom/code/acom/ACOM.Resources/Shared/Lefties/$1.resx
    TARGET_DIR="$(git rev-parse --show-toplevel)/azure/articles/$1/"
    TARGET_FILE="TOC.md"

    if [ $(ls $SOURCE_FILE | wc -l) -eq 0 ]; then
        #echo "$(ls ~/workspace/acom/code/acom/Acom.Json/Data/Lefties/StorSimple.contentmap.json)"
        echo "Can't find the input file $SOURCE_FILE."
        exit 1
    fi

    if [ $(ls $SOURCE_RESX_FILE | wc -l) -eq 0 ]; then
        #echo "$(ls ~/workspace/acom/code/acom/Acom.Json/Data/Lefties/StorSimple.contentmap.json)"
        echo "Can't find the input file $SOURCE_RESX_FILE."
        exit 1
    fi

    # we have our files
    echo "Import source json file: $SOURCE_FILE"
    echo "Import source resx file: $SOURCE_RESX_FILE"
    if [[ ! -d $TARGET_DIR ]]; then
        echo "there is no $TARGET_DIR"
        continue

        heads=$(cat $SOURCE_FILE | jq -r '. | keys_unsorted[]')
        # echo "$heads"
        for slug in $slugs
        do
            if [[ ! -d $slug ]]; then
                TARGET_DIR=$slug
                echo "$slug"
                echo "$(find $(git rev-parse --show-toplevel) -type d -name $slug)"
                ## create the toc.md file location
                ## locate the json and resx files; if not, throw an exception.
                ## write the toc files to the toc.md file under discussion; otherwise, write it somewhere else.
                
                for H1 in $heads
                    do
                    xpath="//data[@name=\""$H1\""]/value/text()"
                    title=$(xmllint --xpath $xpath  $2)
                    echo "# $title" >> $$TARGET_FILE
                    subheads=$(cat $SOURCE_FILE | jq -r ".$H1 | keys[]")
                    #echo "$subheads"
                    for H2 in $subheads
                        do
                            xpath="//data[@name=\""$H2\""]/value/text()"
                            subtitle=$(xmllint --xpath $xpath  $2)
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
            else echo "$slug isn't a directory.'"
            fi


        done

    else
        echo "there IS a $TARGET_DIR"
#        continue

        heads=$(cat $SOURCE_FILE | jq -r '. | keys_unsorted[]')
        # echo "$heads"
        for H1 in $heads
        do
            # replace &amp;
            H1=${H1//&amp;/&}
            xpath="//data[@name=\""$H1\""]/value/text()"
            title=$(xmllint --xpath $xpath  $SOURCE_RESX_FILE)
            title=${title//&amp;/&}
            echo "# $title" >> $TARGET_DIR$TARGET_FILE
            subheads=$(cat $SOURCE_FILE | jq -r ".$H1 | keys[]")
            #echo "$subheads"
            for H2 in $subheads
                do
                    xpath="//data[@name=\""$H2\""]/value/text()"
                    subtitle=$(xmllint --xpath $xpath  $SOURCE_RESX_FILE)
                    subtitle=${subtitle//&amp;/&}
                    article_string=$(cat $SOURCE_FILE | jq -r ".$H1[\"$H2\"]")
                    article_string=${article_string//acom:/https://azure.microsoft.com}
                    article_string=${article_string//link:/} 
                    article_string=${article_string//msdn:/https://msdn.microsoft.com/en-us/library/azure/}
                    
                    if [[ "$article_string" =~ article:.* ]]; then
                    #set -x
                        article_string=${article_string//article:/}
                        article_string="$article_string".md
                    #set +x 
                    fi
                    if [[ "$article_string" =~ link.* ]]; then
                        set -x

                        article_string=${article_string//link:/}
                        set +x
                        fi
                    ## stripping oddity

                    echo "## [$subtitle]($article_string)" >> $TARGET_DIR$TARGET_FILE
            done
        done 
    fi
}


# first, lookup all the tocs we have.
# ls ~/workspace/acom/code/acom/Acom.Json/Data/Lefties/ | grep -oP ".+(?=\.contentmap.json)" | xargs -I {} ls ~/workspace/acom/code/acom/ACOM.Resources/Shared/Lefties/{}.resx
jsontocs=$(ls ~/workspace/acom/code/acom/Acom.Json/Data/Lefties/ | grep -oP ".+(?=\.contentmap.json)")

# for each toc file, locate the corresponding resx file
# if there's a directory, build a toc.md file and put it in that directory'
# otherwise, build a jsontocname.toc.md file and put in the root directory.
for toc in $jsontocs
do
    if [[ $(ls 2>/dev/null ~/workspace/acom/code/acom/ACOM.Resources/Shared/Lefties/$toc.resx | wc -l) -eq 0 ]]; then
        echo "did NOT find the $toc.resx file!"
    else
        #echo "found the $toc.resx file!"
        create_toc $toc
    fi

done




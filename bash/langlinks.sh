#!/bin/bash

linkstotest=$# # this passes the number of arguments passed **after** the command name, which is always the first argument

# feedback; probably not necessary, as it happens so fast
#if [[ $# -eq 1 ]];
#        then 
#        echo "no links passed."
#else
#        echo "There were $linkstotest links passed.";
#fi

declare -a langlinks
count=0

for ((i=1; i<$(($linkstotest + 1)); i++))
        do 

# Feedback: Not necessary
#                printf "\r%d of %d... " $i $linkstotest
                result=$(echo "${!i}"  | egrep "\/[a-z]{2}\-[a-z]{2}\/")
                        if [[ "$result" ]]; then
#                               printf " =====  %s\n" "$result"
                                langlinks[$count]="$result"
                                ((count++))
                        fi
done
# printf "\n"
for ((i=0; i<$count; i++))
        do
                echo "${langlinks[$i]}"
done

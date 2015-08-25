#!/bin/bash

# xargs -I {} curl -sL -w "%{http_code} %{url_effective}\\n" "{}" -o /dev/null | grep ^404

url=$@
linkstotest=$(($# - 1))
if [[ $# -eq 1 ]];
	then 
	echo "no links passed."
else
	echo "There were $linkstotest links passed.";
fi

declare -a missing
count=0

# echo "test: \$0 is $0"
for ((i=1; i < $#; i++))
	do 
		printf "%d of %d: %s\n" $i $linkstotest "${!i}"
		lastlinecount=${#thisstring}

#		thisstring="${!i}"
#		echo "working on: $thisstring"
#		echo "length of this string is ${#thisstring}"
#		printf "\r"
		result=$(curl -sL -w "%{http_code} %{url_effective}\\n" "${!i}" -o /dev/null | grep ^404)
			if [[ "$result" ]]; then
				printf " -- %s\n" "$result"
				missing[$count]='$result'
				#echo "${404s[$i]}"
				((count++))
			fi
#		echo "last line count is $lastlinecount"
done

for link in missing
	do 
		echo "something here: ${!link}"
done




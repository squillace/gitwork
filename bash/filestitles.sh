#!/bin/bash

for file in $(ls -p $1 | grep -v / | grep -v classic)
    do
	echo $(grep -oP "(?<=pageTitle=\").*?(?=\")" $file)
	echo $(grep -oP -m 1 "^#{1} *.*\w*?" $file)
#	echo "$file",$(grep -P -m 1 "^#{1} *.*\w*?" $file | sed "s/#//g" | sed "s/^ //g" | sed "s/^.*>//g")
done

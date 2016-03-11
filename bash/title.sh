#!/bin/bash
#echo $1
grep -oP "(?<=pageTitle=\").*?(?=\")" $1
grep -P -m 1 "^#{1} *.*\w*?" $1 | sed "s/#//g" | sed "s/^ //g" | sed "s/^.*>//g"
grep -oP "(?<=description=\").*?(?=\")" $1
grep -oP "(?<=tags=\").*?(?=\")" $1

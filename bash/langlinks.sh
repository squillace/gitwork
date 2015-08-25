#!/bin/bash

# echo "$#"
langlinkregex="\/[a-z]{2}\-[a-z]{2}/+"
foundlinks=$(egrep "$langlinkregex" $1 | sort | uniq -u)
echo "$foundlinks" 

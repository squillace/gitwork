#!/bin/bash
# links=$(ls *.md | xargs -I {} grep -noHP "(?<=\[AZURE.INCLUDE \[learn-about-deployment-models\]\().*?(?=\)\])" {})
# links=$(grep -oP "(?<=\]\().*?(?=\))" 2>/dev/null $1 | sed "s/#.*?//g" | grep -o *.md | uniq)
# links=$(grep -oP "(?<=\]\().*?(?=\))" 2>/dev/null $1)
file=""
linenum=""
includetext=""
while IPS='\:' read file
do
    echo "$file"
    linenum=$(grep -onP "\[AZURE.SELECTOR.*" $file | sed "s/:.*//g")
    lines_to_cut=$(grep -noHPz "(?s)\[AZURE.SELECTOR.*?^\s" $file | sed "/^$/d" | wc -l)
    echo "we will cut $lines_to_cut lines"
    ending_line_num=$((linenum + lines_to_cut))
    echo "starting at line: $linenum"
    echo "sedline: $linenumd","$ending_line_numd"
    sed -i'' -e "$linenum","$ending_line_num"d $file 
    
    #file_PATH=$(find $(git rev-parse --show-toplevel) -type f -name "${file[@]}")
    #MEDIAPATH="$(dirname $file_PATH)/media/${file[@]%.md}"
done <<< "$(ls *.md | xargs -I {} grep -nolHPz "(?s)\[AZURE.SELECTOR.*?^\s" {})"

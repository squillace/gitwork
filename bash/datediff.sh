#!/bin/bash

changesFromCommit=$1
changesToCommit=$2
fileToDiff=$3

echo "from: $changesFromCommit"
echo "to: $changesToCommit"
echo "file: $fileToDiff"

echo "In $changesFromCommit: $(git log -1 --format="%ad" $changesFromCommit -- $fileToDiff)"
echo "In $changesToCommit: $(git log -1 --format="%ad" $changesToCommit -- $fileToDiff)"

# echo "$(date -utc -date $(git log -1 --format="%ad" $changesFromCommit -- $fileToDiff) +%s)"
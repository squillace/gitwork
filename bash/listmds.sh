#!/bin/bash

for files in $(ls -R *.md)
do
	echo "${files[@]}"
done

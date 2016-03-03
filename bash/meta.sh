#!/bin/bash

file=$(find $(git rev-parse --show-toplevel) -name "$1" -type f)
gsed -n "/<properties/,/ms.author.*/p" "$file"


#!/bin/bash

find $(git rev-parse --show-toplevel) -name "*.md" -type f -exec grep -il "$1" {} +

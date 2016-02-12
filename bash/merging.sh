#!/bin/bash

git fetch squillace
git checkout $1
git merge -m "fixing the merge issues -- rasquill" vm-refactor-staging
git checkout vm-refactor-staging
git merge --no-ff -m "bringing the fix back to the common branch" $1
echo "git push squillace\r"

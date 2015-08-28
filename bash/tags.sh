#!/bin/bash

sed -n '/<tags/,/ms.author.*/p' $1

#!/bin/bash

sed -n '/<properties/,/editor.*/p' $1


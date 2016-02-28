#!/bin/bash

find $(git rev-parse --show-toplevel) -type f -name "$1"

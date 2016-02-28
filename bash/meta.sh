#!/bin/bash

$(find "$(git rev-parse --show-toplevel)" -name "$1" -type f)

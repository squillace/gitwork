#!/bin/bash

azure group log show $1 --last-deployment --json | jq ".[] | select(.status.value == \"Failed\")"

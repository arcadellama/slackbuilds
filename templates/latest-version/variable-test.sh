#!/usr/bin/env bash

VAR1=""
VAR2=""
VAR3="${VAR3:-}"
VAR4="${VAR4:-$VAR1}"

if [ -z "$VAR1" ]; then
    echo "VAR1 is empty."
else
    echo "VAR1 is not empty."
fi


if [ -z "$VAR2" ]; then
    echo "VAR2 is empty."
else
    echo "VAR2 is not empty."
fi


if [ -z "$VAR3" ]; then
    echo "VAR3 is empty."
else
    echo "VAR3 is not empty."
fi


if [ -z "$VAR4" ]; then
    echo "VAR4 is empty."
else
    echo "VAR4 is not empty."
fi



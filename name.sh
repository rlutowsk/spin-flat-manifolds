#!/bin/bash

. carat-env.sh

if [ ! -f "$1" ]; then
    echo "provide filename as the first argument"
    exit 1
fi

Name -c $1 2>/dev/null
#!/bin/bash

. carat-env.sh

shopt -s extglob

if [ ! -d "$1" ]; then
    echo "provide directory as the first argument"
    exit 1
fi

cd $1

for q in +(group|max|min).+([0-9]); do
    for x in $q.+([0-9]).+([0-9]); do
        echo -n "$x: "
        Extensions pres.$q $x -S -F
        if [ $? -ne 0 ]; then
            echo $x >> extensions.fail.log
        fi
    done
done
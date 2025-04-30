#!/bin/bash

. carat-env.sh

shopt -s extglob

if [ ! -d "$1" ]; then
    echo "provide directory as the first argument"
    exit 1
fi

cd $1

for q in +(group|max|min).+([0-9]); do
    QtoZ -D $q
    if [ $? -ne 0 ]; then
        echo $q >> qtoz.fail.log
        cp $q $q.1.1
    fi
done

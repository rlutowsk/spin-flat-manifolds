#!/bin/bash

shopt -s extglob

if [ ! -d "$1" ]; then
    echo "provide directory as the first argument"
    exit 1
fi

cd $1

echo "return ["
for q in +(group|max|min).+([0-9]); do
    for x in $q.+([0-9]).+([0-9]).+([0-9]); do
        echo "rec( qname := \"$q\", name := \"$x\" ),"
    done
done
echo "];"
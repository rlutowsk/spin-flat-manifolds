#!/bin/bash

# the output of this file is ALWAYS 
#
# anames.g
#
out=anames.g

if [ ! -d "$1" ]; then
    echo "provide directory as the first argument"
    exit 1
fi


echo -n "return " | tee $out
find $1 -regextype egrep -regex '.*/(group|min|max)\.[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | jq -R -s 'split("\n")[:-1]' | tee -a $out
echo ";" | tee -a $out
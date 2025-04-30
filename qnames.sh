#!/bin/bash

# the output of this file is ALWAYS 
#
# qnames.g
#
out=qnames.g

source carat-env.sh

if [ ! -d "$1" ]; then
    dir=$CARAT_HOME
else
    dir=$1
fi


echo -n "return " | tee $out
find $dir -regextype egrep -regex '.*/(group|min|max)\.[0-9]+$' | jq -R -s 'split("\n")[:-1]' | tee -a $out
echo ";" | tee -a $out
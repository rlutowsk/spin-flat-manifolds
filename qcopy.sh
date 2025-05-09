#!/bin/bash

source carat-env.sh

function help {
    echo "Usage: ./qcopy.sh [ carat_directory ] output_directory" 1>&2
}

if [ $# -eq 0 ]; then
    help
    exit 1
elif [ $# -eq 1 ]; then
    dir=$CARAT_HOME
    out=$1
else
    dir=$1
    out=$2
fi;

[ -e "$dir" ] || mkdir "$dir"

if [ ! -d "$dir" -o ! -d "$out" ]; then
    help
    exit 1
fi



find $dir -regextype egrep -regex '.*/(pres\.|)(group|min|max)\.[0-9]+$' -exec cp '{}' $out \;
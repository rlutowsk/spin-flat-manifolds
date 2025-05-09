#!/bin/bash

help() {
    echo "Usage: $1 {[-q|-z|-a]} directory"
}

q=false
z=false
a=false

while getopts "qzah" opt; do
  case "$opt" in
    q)
      q=true
      ;;
    z)
      z=true
      ;;
    a)
      a=true
    ;;
    h)
      help $0
      exit 1
      ;;
  esac
done

shift $((OPTIND - 1))

if [ ! -d "$1" ]; then
    echo "provide directory as the first argument"
    exit 1
fi

dir=$1

if $q; then
    find $dir -regextype egrep -regex '.*/(group|min|max)\.[0-9]+$' | jq -R -s 'split("\n")[:-1]' 
    exit 0
fi;

if $z; then
    find $dir -regextype egrep -regex '.*/(group|min|max)\.[0-9]+\.[0-9]+\.[0-9]+$' | jq -R -s 'split("\n")[:-1]' 
    exit 0
fi;

if $a; then
    find $dir -regextype egrep -regex '.*/(group|min|max)\.[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | jq -R -s 'split("\n")[:-1]' 
    exit 0
fi;

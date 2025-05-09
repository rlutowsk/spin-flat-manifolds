#!/bin/bash

help() {
    echo "Usage: $1 {[-q|-z|-a]} directory"
}

qcount=false
zcount=false
acount=false

while getopts "qzah" opt; do
  case "$opt" in
    q)
      qcount=true
      ;;
    z)
      zcount=true
      ;;
    a)
      acount=true
    ;;
    h)
      help $0
      exit 1
      ;;
  esac
done

shift $((OPTIND - 1))

dir=$1
if [ ! -d "$dir" ]; then
    help $0
    exit 1
fi

if $qcount; then
    echo -n "Number of Q classes: "
    find $dir -regextype egrep -regex '.*/(group|min|max)\.[0-9]+$' | wc -l
fi;

if $zcount; then
    echo -n "Number of Z classes: "
    find $dir -regextype egrep -regex '.*/(group|min|max)\.[0-9]+\.[0-9]+\.[0-9]+$' | wc -l
fi;

if $acount; then
    echo -n "Number of Aff classes: "
    find $dir -regextype egrep -regex '.*/(group|min|max)\.[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | wc -l
fi;
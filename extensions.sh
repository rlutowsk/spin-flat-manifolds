#!/bin/bash

. carat-env.sh

num_jobs=4

while getopts "hj:" opt; do
  case "$opt" in
    j)
        num_jobs=$OPTARG
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

cd $1

find ./ -regextype egrep -regex '.*/(group|min|max)\.[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' -delete 

[ -e extensions.err ] && rm extensions.err

cat > job.sh << EOF
#!/bin/bash
shopt -s extglob
export PATH=$PATH
file=\$1
pres="pres.\${file%%.+([0-9]).+([0-9])}"
res=\$(Extensions \$pres \$file -S -F)
if [ \$? -ne 0 ]; then
    echo \$1 >> extensions.err
else
    echo "\$file: \$res"
fi
EOF

find ./ -regextype egrep -regex '.*/(group|min|max)\.[0-9]+\.[0-9]+\.[0-9]+$' -printf "%f\n" > files.txt

parallel -j $num_jobs bash job.sh :::: files.txt

rm job.sh files.txt

#!/bin/bash

. carat-env.sh

all=false
num_jobs=4

while getopts "ahj:" opt; do
  case "$opt" in
    a)
        all=true
        ;;
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

find $1 -regextype egrep -regex '.*/(group|min|max)\.[0-9]+\.[0-9]+\.[0-9]+$' -delete

if $all; then
    find $1 -regextype egrep -regex '.*/(group|min|max)\.[0-9]+$' -printf "%f\n" > $1/files.txt
else

    cat > $1/run.g << EOF
    Read("names.g");
    E1InCC := function( cc )
        return 1 in Eigenvalues( Rationals, Representative( cc ) );
    end;
    FilterRecord := function( r )
        local res;
        Print(r.name, " ... \c");
        res := ForAll( ConjugacyClasses(Group(r.generators)), E1InCC  );
        Print(res, "\n");
        return res;
    end;
    r := Filtered( ReadQCaratDir("$1"), FilterRecord );
    n := List(r, x->x.name);
    PrintTo("$1/files.txt", "");
    for x in n do
        AppendTo("$1/files.txt", x, "\n");
    od;
    quit;
EOF
    gap -b $1/run.g
    #rm $1/run.g
fi

cd $1

[ -e qtoz.err ] && rm qtoz.err

cat > job.sh << EOF
#!/bin/bash
export PATH=$PATH
QtoZ -D \$1 >/dev/null 2>&1
if [ \$? -ne 0 ]; then
    echo \$1 >> qtoz.err
    # at the moment error ocurrs in simple cases
    cp \$1 \$.1.1
    echo "\$1: error -> copy to \$.1.1"
else
    res=\$(find ./ -regextype egrep -regex ".*/\$1\.[0-9]+\.[0-9]+$" | wc -l)
    echo "\$1: \$res"
fi
EOF


parallel -j $num_jobs bash job.sh :::: files.txt

# rm job.sh files.txt

#for q in +(group|max|min).+([0-9]); do
#    QtoZ -D $q
#    if [ $? -ne 0 ]; then
#        echo $q >> qtoz.fail.log
#        cp $q $q.1.1
#    fi
#done

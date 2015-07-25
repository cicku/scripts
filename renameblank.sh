#!/bin/bash

for f in * ;
do
    nn=`echo $f | tr "[:blank:]" "_"`
    if [ ! "$nn" = "$f" ]; then
        mv "$f" "$nn"
        let "cm = cm + 1"
    fi
done

echo "$cm modification(s)"

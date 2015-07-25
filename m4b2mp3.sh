#!/bin/sh

for i in *m4a
do
    x=$(basename "$i" .m4a)
    faad "$i"
    lame --alt-preset 160 --tt "$x" --ta "college de france" --tl "college de france" $x.wav $x.mp3
    rm -f *wav
done

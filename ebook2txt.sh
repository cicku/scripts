#!/bin/bash

mkdir -p temp

for i in *.*htm*
do
    lynx -dump -nolist -nomargins -width=80 -force_html \
         -assume_charset=utf-8 "$i" > temp/"$i"
done

cd temp/

cat <<EOF > foo.txt
   AUTEUR
   TITRE 
   TITRE ORIGINAL
   ANNÉE
   TRADUCTION
   ENCODAGE

EOF

for i in *.*htm*
do
    cat "$i" >> foo.txt
    echo -en "\n\n\n" >> foo.txt
done

sed -i "s/’/'/g" foo.txt
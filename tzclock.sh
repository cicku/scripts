#!/bin/ksh

DOW=$( date +%a )
SHORT=$( date +'%d %b' )
if [ -n "${IN_RPECHO}" ] ; then
        printf " "
fi
printf "%-8.8s% -7.7s%-9.9s %-6.6s\n" "$DOW" "Eastern" " Acapulco" "Paris"
if [ -n "${IN_RPECHO}" ] ; then
        printf " "
fi
printf "%-7.7s " "$SHORT"
zdump Canada/Eastern Mexico/General Europe/Paris | \
        awk '{print $5}' | \
        cut -c1-5 | \
        while read TIME ; do
        printf " %-6.6s " "$TIME"

done

printf "\n"
#!/bin/sh

if [ -n "${IN_RPECHO}" ] ; then
        printf " "
fi
printf "%-7.7s%-7.7s%-7.7s%-6.6s\n" "Acap." "East." "Paris" "Japan"
if [ -n "${IN_RPECHO}" ] ; then
        printf " "
fi
zdump Mexico/General Canada/Eastern  Europe/Paris Japan | \
        awk '{print $5}' | \
        cut -c1-5 | \
        while read TIME ; do
        printf "%-6.6s " "$TIME"

done

printf "\n"

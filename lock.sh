#!/bin/bash
 
# Copied from https://github.com/meskarune/i3lock-fancy

IMAGE=/tmp/lock.png

scrot $IMAGE
convert $IMAGE -level 0%,100%,0.8 -blur 0x2 -fill "#fcefba" -pointsize 26 -gravity center -annotate +0+100 'Type password to unlock' - | composite -gravity center lock.png - $IMAGE
i3lock -i $IMAGE
rm $IMAGE

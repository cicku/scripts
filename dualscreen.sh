#!/bin/sh

xrandr --verbose --addmode VGA1 1024x768
xrandr --verbose --output VGA1 --mode 1024x768
#xrandr --output VGA1 --right-of LVDS1
xrandr --verbose --output VGA1 --same-as LVDS1

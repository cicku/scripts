#!/bin/bash

# crousloops.sh - because CROUS networks need a script
# Last update Time-stamp: <2015-08-06 18:15:01 (f6k)> 
# Author: f6k <f6k@opmbx.org>

# ABOUT.  For murky reason, the wifi network of the CROUS and its captive
# portal disconnect the client after some time, With an infinite loop
# crousloops.sh attempt to automate the process by checking if wlan0 is
# connected -- and reconnect it if it's not -- and by re-auth with captive
# portal if necessary. Note that, sometimes and mostly because of power
# outage, the access point is not present; so I added a function, and its
# corresponding option, that play a sound when it reappears.

# REQUIRES.  coreutils, iw, dhcpcd, curl, aplay.

# OPTIONS.  crousloops.sh has two options: `-l' or `--loop' for the loop used
# to reconnecte to the access point and to re-auth to the captive portal.
# `-t' or `--test' is for testing the presence of the access point. If you
# don't set options, crousloops.sh will be launched with `-l' as default. See
# `-h' or `--help' for summary.

# IMPORTANT NOTE.  CROUSLOOPS.SH HAS BEEN SPECIFICALLY MADE FOR THE CROUS WERE
# I LIVE, SO BE SURE TO CHECK WHAT `curl' IS DOING IN `startloop' FUNCTION AND
# ADAPT IT ACCORDING TO YOUR NEEDS. UNLESS YOU LIVE IN THE SAME CROUS AS ME,
# THIS SCRIPT WILL NOT WORK PROPERLY UNTIL YOU HAVE CORRECTLY SET IT.

# CONFIGURATION.  Two variables are needed to be configured: PASSFILE and
# SOUND. PASSFILE is the file used for captive portal credentials (this file
# should be chmod 600 for more security). On a single line in it put "user
# password" without quotes. Note that you'll need to put the full path in this
# variable. SOUND is the path to whatever sound that aplay can handle. If you
# don't want sound, just put an empty string or delete the corresponding line
# in function `starttest' below.

# KNOWN BUG.  `iwconfig' use only CROUS's essid to connect to the access
# point. So, normally, it uses the best one of those found. Sometimes
# unfortunately, for some reason, it doesn't work so `iwconfig' needs to be
# (re)launched with the essid, an AP and its specific channel. The script
# still doesn't handle that, so it has to be done manually.

# crousloops.sh is shared by license Dual Beer-Ware/WTFPLv2.

# THE BEER-WARE LICENSE:
# As long as you retain this notice you can do whatever you want with this
# stuff. If we meet some day, and you think this stuff is worth it, you can
# buy me a beer in return.

# DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# Version 2, December 2004
# Copies of this license document, and changing it is allowed as long
# as the name is changed.
# DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
# TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
# 0. You just DO WHAT THE FUCK YOU WANT TO.

# ┌─┐┌─┐┌┐┐┬─┐o┌─┐
# │  │ ││││├─ ││ ┬
# └─┘┘─┘ └┘│  │└─┘
########### CONFIG

# Variables that need to be modified.
PASSFILE="/home/f6k/.crousloops"
SOUND="~/t/TokyoTrainStation.AdiumSoundset/On.wav"

# ┐ ┬┬─┐┬─┐o┬─┐┬─┐┬  ┬─┐┐─┐
# │┌┘│─┤│┬┘││─┤│─││  ├─ └─┐
# └┘ ┘ ││└┘│┘ │┴─┘└─┘┴─┘──┘
################# VARIABLES

# Name by which this script was invoked.
PROGNAME=$(basename $0)
VERSION="0.3.2rev11 (2015-08-06)"

# Login and password for captive portal.
LOGIN="$(cut -d" " -f1 $PASSFILE)"
PASSWORD="$(cut -d" " -f2 $PASSFILE)"

# Just to prevent hairy quoting and escaping later.
bq='`'
eq="'"

# Display some usage for details.
USAGE="Usage: $PROGNAME {option}

NB: The default option used when none is specified is $bq--loop$eq.

Options are:
-h, --help                 You're looking at it
-l, --loop                 Start a loop to auto-reconnect and login
-t, --test                 Check until CROUS access point is detected
"

# Header when program's launched.
HEADER="CROUSLOOPS Version $VERSION
Automation script for CROUS wireless network
Hint: hit \`ctrl+\' to end the loop
"

# Default option used when none is specified.
CASE=loop

# ┬─┐┬ ┐┌┐┐┌─┐┌┐┐o┌─┐┌┐┐┐─┐
# ├─ │ │││││   │ ││ ││││└─┐
# │  └─┘ └┘└─┘ │ │┘─┘ └┘──┘
################# FUNCTIONS

# Infinite loop to stay online.
function startloop
{
    clear && tput cup 50
    echo "$HEADER"

    # Display feedback for the first launch when all is green.
    if ifconfig wlan0 | grep -q "inet " ; then
        echo "First check: wlan0 is already up and running"
        echo "["$(date "+%d-%H%M%S")"] Standing by..."
    fi

    while true ; do
        if ifconfig wlan0 | grep -q "inet " ; then
            # wlan0 connected but there's no ping: re-auth on captive portal.
            ping -c 1 193.51.224.170 &> /dev/null
            if [ $? -ne 0 ] 
            then
                echo "["$(date "+%d-%H%M%S")"] CROUS auth required"
                echo -en " -> Login in... "
                curl -s -k -d 'redirurl=http:%2F%2Fgoogle.com&auth_user='$LOGIN'&auth_pass='$PASSWORD'&CHKBOX1=1&accept=Continue' 'https://portail-captif.crous.unicaen.fr:8003/index.php?zone=crous_etu'
                ping -c 1 193.51.224.170 &> /dev/null
                if [ $? -eq 0 ]
                then
                    echo "OK"
                else
                    echo "FAIL! Waiting for the next loop..."
                fi 
            fi
            sleep 20
        else
            # Looks like wlan0 is not connected: reconnect it.
            echo "["$(date "+%d-%H%M%S")"] Network is down; reconnecting"
            echo -en " -> Cleaning wlan0... "
            ifconfig wlan0 down
            sleep 1
            ifconfig wlan0 up
            sleep 1
            echo "done"
            echo -en " -> Configuring wlan0... "
            iwconfig wlan0 essid "crous"
            sleep 10
            echo "done"
        fi
    done
}

# Infinite loop to check when CROUS AP is back.
# TODO: should I add this checkup in the main loop?
function starttest
{
    clear && tput cup 50
    echo "$HEADER"

    while true; do
        if iwlist wlan0 scan|grep -q crous; then
            echo "["$(date "+%d-%H%M%S")"] A CROUS access point is UP!"
            aplay -q $(echo $SOUND)
            exit
        else
            echo "["$(date "+%d-%H%M%S")"] No CROUS access point found"
        fi
        sleep 300
    done
}

# ┬ ┬┬─┐┬─┐┬─┐  ┐ ┬┬─┐  ┌─┐┌─┐┐
# │─┤├─ │┬┘├─   │││├─   │ ┬│ ││
# │ ┴┴─┘│└┘┴─┘  └┴┘┴─┘  └─┘┘─┘o
################### HERE WE GO!

# Parse command line arguments.
while test $# != 0; do
    case "$1" in
        -h|--help)
            CASE=help
            shift
            ;;
        -l|--loop)
            CASE=loop
            shift
            ;;
        -t|--test)
            CASE=test
            shift
            ;;
        -- ) # Stop option processing
            shift
            break
            ;;
        -? | --* )
            case "$1" in
                --*=* ) arg=`echo "$1" | sed -e 's/=.*//'` ;;
                *)      arg="$1" ;;
            esac
            exec 1>&2
            echo "$PROGNAME: unknown or ambiguous option $bq$arg$eq"
            echo "$PROGNAME: Use $bq--help$eq for a list of options."
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# For every case, do something!
case "$CASE" in
    help)
        echo "$USAGE" 1>&2
        exit 0
        ;;
    loop)
        startloop
        ;;
    test)
        starttest
        ;;
esac

exit 0

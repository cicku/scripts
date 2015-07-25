#!/bin/bash
# Original version :
# http://www.neowin.net/forum/topic/961792-pimp-my-bash-script/
# Modified by fgk for personal use.

# Radio names list
RADIO_NAME_ARRAY=(
"RadioCanada"
"EspaceMusic"
"FranceInter"
"FranceInfo"
"Europe1"
"RDI"
"SPVM"
"LeMouv"
"RadioNova"
"RadioBazarnaom"
"DeepSpace1"
"SpaceStation"
"604"
"SecretAgent"
)

# Radio URL list
RADIO_URL_ARRAY=(
"http://2QMTL0.akacast.akamaistream.net:80/7/953/177387/v1/rc.akacast.akamaistream.net/2QMTL0"
"http://7qmtl0.akacast.akamaistream.net/7/445/177407/v1/rc.akacast.akamaistream.net/7QMTL0"
"http://mp3.live.tv-radio.com/franceinter/all/franceinterhautdebit.mp3"
"http://mp3.live.tv-radio.com/franceinfo/all/franceinfo.mp3"
"http://vipicecast.yacast.net/europe1.m3u"
"http://RDIRADIO.akacast.akamaistream.net:80/7/501/177423/v1/rc.akacast.akamaistream.net/RDIRADIO"
"http://relay.broadcastify.com:80/796464909"
"http://mp3.live.tv-radio.com/lemouv/all/lemouvhautdebit.mp3"
"http://broadcast.infomaniak.net/radionova-high.mp3"
"http://str20.creacast.com/bazarnaom"
"http://ice.somafm.com/deepspaceone"
"http://ice.somafm.com/spacestation"
"http://ice.somafm.com/suburbsofgoa"
"http://ice.somafm.com/secretagent"
)

# Generate radios list
gen_list() {
    local TOTAL_MEMB=${#RADIO_NAME_ARRAY[@]}
    for (( i=0;i<$TOTAL_MEMB;i++));do
        echo -n ${RADIO_NAME_ARRAY[${i}]} " "
        echo -n ${RADIO_URL_ARRAY[${i}]} " "
    done
}

# Get the URL
get_radio_url() {
    local TOTAL_MEMB=${#RADIO_NAME_ARRAY[@]}
    for (( i=0;i<$TOTAL_MEMB;i++));do
        if [ "$1" == ${RADIO_NAME_ARRAY[${i}]} ];then
            VARRAD=${RADIO_URL_ARRAY[${i}]}
            break
        fi
    done
}

# Show the menu
show_menu() {
    dialog --backtitle "Radio tunner" \
           --title "Radio stations" \
           --menu "Choose your station:" 16 60 9 $VARRAD 2> .tempfile

    output=`cat .tempfile`
    rm -f .tempfile
    clear
}

# Play the stream
tune_radio() {
    if [ $output ];then
        get_radio_url $output
        mpg123 -vC $VARRAD
    else
        exit 0
    fi
}

export VARRAD=$(gen_list)

show_menu
tune_radio

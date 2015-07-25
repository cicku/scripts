#!/bin/bash

TIME="$1"

utimer -c $TIME

# if '[ -z "$DISPLAY" ]' ; then
#     echo "Your cake is hot! Press [q] to quit."
# else
#     while true
#     do
#         ratpoison -c "echo Your cake is hot"
#         sleep 30
#     done &
# fi
echo "Your cake is hot! Press [q] to quit."

mplayer -really-quiet -loop 0 ~/t/rubberd.wav
pkill eggtimer.sh

exit 0

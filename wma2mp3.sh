#!/bin/bash
#
# Dump wma to mp3
for i in *.wma
do
 if [ -f "$i" ]; then
 rm -f "$i.wav"
 mkfifo "$i.wav"
 mplayer -quiet -vo null -vc dummy -af volume=0,resample=44100:0:1 -ao pcm:waveheader:file="$i.wav" "$i" &
 dest=`echo "$i"|sed -e 's/wma$/mp3/'`
 lame -V0 -h -b 160 --vbr-new "$i.wav" "$dest"
 rm -f "$i.wav"
fi
done
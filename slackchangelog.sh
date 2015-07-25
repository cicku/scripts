#!/bin/sh

# just a little thing to track slackware changelog

wget -q ftp://ftp.slackware.com/pub/slackware/slackware-14.0/ChangeLog.txt \
     -O /tmp/slacklog.$$
diff /tmp/.slack-changelog /tmp/slacklog.$$ | more
mv /tmp/slacklog.$$ /tmp/.slack-changelog && rm -f /tmp/slacklog.$$

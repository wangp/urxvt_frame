#!/bin/sh -e
# 
# This script starts the urxvt daemon (urxvtd) if not already running,
# before running urxvt_frame.  You will need to configure urxvt_frame
# to run 'urxvtc' instead of 'urxvt' in urxvt_frame.conf.

# Check if urxvtd running for the current user.
if ! pgrep -u "$UID" urxvtd >/dev/null
then
    urxvtd -q -o -f
fi

PROG=$(dirname $0)/urxvt_frame

if test $# -eq 0
then
    exec "$PROG"
elif test "$1" = "-e"
then
    exec "$PROG" "$@"
else
    exec "$PROG" -e "$@"
fi

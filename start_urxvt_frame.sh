#!/bin/zsh

if ! pgrep -u $UID urxvtd >/dev/null
then
    urxvtd -q -o -f
fi

PROG=${0:h}/urxvt_frame

if (( $# == 0 ))
then
    exec $PROG
elif [[ $1 == "-e" ]]
then
    exec $PROG "$@"
else
    exec $PROG -e "$@"
fi

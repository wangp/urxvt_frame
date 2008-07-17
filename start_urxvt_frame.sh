#!/bin/zsh

if ! pgrep -u $UID urxvtd >/dev/null
then
    urxvtd -q -o -f
fi

exec ${0:h}/urxvt_frame "$@"

#!/bin/zsh

if ! pgrep -u $UID urxvtd >/dev/null
then
    urxvtd &
fi

exec ${0:h}/urxvt_frame "$@"

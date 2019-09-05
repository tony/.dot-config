#!/bin/bash
[ "$XDG_SESSION_TYPE" = x11 ] || exit 0

xrandr --output DP-4 --scale 0.75x0.75

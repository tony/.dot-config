#!/bin/sh
`dirname $0`/one-monitor.sh
xrandr --output DP3 --mode 2560x1440 --pos 0x0 --rotate normal --output DP2 --off --output DP1 --off --output HDMI3 --off --output HDMI2 --off --output HDMI1 --off --output LVDS1 --mode 1366x768 --pos 2560x672 --rotate normal --output VGA1 --off

#! /usr/bin/env python3
# -*- coding: utf-8 -*-

import subprocess

from i3pystatus import Status

status = Status(standalone=True)

# Displays clock like this:
# Tue 30 Jul 11:59:46 PM KW31
#                          ^-- calendar week
status.register("clock",
                format="%a %-d %b %X KW%V",)

# Shows the average load of the last minute and the last 5 minutes
# (the default value for format is used)
status.register("load")

# Shows your CPU temperature, if you have a Intel CPU
status.register("temp",
                format="{temp:.0f}°C",)

# The battery monitor has many formatting options, see README for details

# This would look like this, when discharging (or charging)
# ↓14.22W 56.15% [77.81%] 2h:41m
# And like this if full:
# =14.22W 100.0% [91.21%]
#
# This would also display a desktop notification (via dbus) if the percentage
# goes below 5 percent while discharging. The block will also color RED.
status.register("battery",
                format="{status}/{consumption:.2f}W {percentage:.2f}% [{percentage_design:.2f}%] {remaining:%E%hh:%Mm}",
                alert=True,
                alert_percentage=5,
                status={
                    "DIS": "↓",
                    "CHR": "↑",
                    "FULL": "=",
                },)

# This would look like this:
# Discharging 6h:51m
status.register("battery",
                format="{status} {remaining:%E%hh:%Mm}",
                alert=True,
                alert_percentage=5,
                status={
                    "DIS":  "Discharging",
                    "CHR":  "Charging",
                    "FULL": "Bat full",
                },)

# Displays whether a DHCP client is running
status.register("runwatch",
                name="DHCP",
                path="/var/run/dhclient*.pid",)

# Shows the address and up/down state of eth0. If it is up the address is shown in
# green (the default value of color_up) and the CIDR-address is shown
# (i.e. 10.10.10.42/24).
# If it's down just the interface name (eth0) will be displayed in red
# (defaults of format_down and color_down)
#
# Note: the network module requires PyPI package netifaces-py3
status.register("network",
                interface="eth0",
                format_up="{v4cidr}",)

# Has all the options of the normal network and adds some wireless specific things
# like quality and network names.
#
# Note: requires both netifaces-py3 and basiciw
status.register("wireless",
                interface="wlan0",
                format_up="{essid} {quality:03.0f}%",)

# Shows disk usage of /
# Format:
# 42/128G [86G]
status.register("disk",
                path="/",
                format="{used}/{total}G [{avail}G]",)

# Shows pulseaudio default sink volume
#
# Note: requires libpulseaudio from PyPI
status.register("alsa",
                format="♪{volume}",)

# Shows mpd status
# Format:
# Cloud connected▶Reroute to Remain
status.register("mpd",
                format="{title}{status}{album}",
                status={
                    "pause": "▷",
                    "play": "▶",
                    "stop": "◾",
                },)

status.run()

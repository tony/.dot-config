#!/bin/sh

export BASE16_SCHEME="tomorrow-night"
BASE16_SHELL="$HOME/.config/base16-shell/"
BASE16_FILE="$BASE16_SHELL/scripts/base16-$BASE16_SCHEME.sh"
[[ -s $BASE16_FILE ]] && . $BASE16_FILE

[ -n "$PS1" ] && [ -s $BASE16_SHELL/profile_helper.sh ] && eval "$($BASE16_SHELL/profile_helper.sh)"

#!/bin/sh

export XMODIFIERS='@im=fcitx'

export XIM=fcitx
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=xim
export XMODIFIERS=@im=fcitx

fcitx &
xrdb -load ~/.Xresources &
xscreensaver -no-splash &
xdg-user-dirs-update &

if `which keychain` ; then
    eval `keychain --eval --agents ssh`
fi

exec $1

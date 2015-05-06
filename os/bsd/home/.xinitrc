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

feh --bg-scale /usr/local/share/wallpapers/Damselfly/contents/images/2559x1600.jpg 

exec $1

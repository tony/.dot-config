#!/bin/sh

# for python-for-android (standalone distribute.sh usage) 
# + buildozer

if [ -d $HOME/.buildozer/android/platform ] &&
   [ -d $HOME/.buildozer/android/platform/android-ndk-r9c/ ] &&
   [ -d $HOME/.buildozer/android/platform/android-sdk-21/ ]; then
    export ANDROIDNDKVER=r9c
    export ANDROIDNDK=~/.buildozer/android/platform/android-ndk-r9c
    export ANDROIDSDK=~/.buildozer/android/platform/android-sdk-21
fi

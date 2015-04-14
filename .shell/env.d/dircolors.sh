#!/bin/sh

# dircolors
if [ -f dircolors ]; then
    eval `dircolors ~/.dircolors-solarized/dircolors.256dark`
elif [ -f /opt/local/usr/bin/gdircolors ]; then  # macports gdircolors
    eval `gdircolors ~/.dircolors-solarized/dircolors.256dark`
fi

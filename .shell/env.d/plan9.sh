#!/bin/sh

if [ -d /usr/local/plan9 ]; then
    PLAN9=/usr/local/plan9; export PLAN9
    # PATH=$PATH:$PLAN9/bin; export PATH
fi

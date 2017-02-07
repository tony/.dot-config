#!/bin/sh

if [ -d /Applications/Postgres.app/Contents/Versions/9.4/bin ]; then
    pathappend /Applications/Postgres.app/Contents/Versions/9.4/bin
fi

if [ -d /Applications/Postgres.app/Contents/Versions/9.6/bin ]; then
    pathappend /Applications/Postgres.app/Contents/Versions/9.6/bin
fi

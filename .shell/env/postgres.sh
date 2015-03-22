#!/bin/sh

## postgres paths
if [ -d /opt/local/lib/postgresql93/bin ]; then  # macports
    pathappend /opt/local/lib/postgresql93/bin
fi

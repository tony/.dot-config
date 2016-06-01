#!/bin/sh

if [ -f /usr/local/bin/docker-machine ]; then
    eval $(/usr/local/bin/docker-machine env default)
fi

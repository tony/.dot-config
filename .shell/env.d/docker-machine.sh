#!/bin/sh

if [ -f /usr/local/bin/docker-machine ]; then
    if [[ `docker-machine status default` == 'Running' ]]; then
        eval $(/usr/local/bin/docker-machine env default)
    fi
fi

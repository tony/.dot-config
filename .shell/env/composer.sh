#!/bin/sh

if [ -d $HOME/.composer/vendor/bin ]; then
    pathprepend ~/.composer/vendor/bin
fi

#!/bin/sh

if command -v ipdb > /dev/null 2>&1 || command -v ipdb3 > /dev/null 2>&1; then
    export PYTHONBREAKPOINT=ipdb.set_trace
fi

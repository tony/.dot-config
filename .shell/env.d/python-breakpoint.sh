#!/bin/sh

if command -v ipdb > /dev/null 2>&1 || command -v ipdb3 > /dev/null 2>&1; then
    export PYTHONBREAKPOINT=ipdb.set_trace
fi

python -c "import ipython" &> /dev/null

if [[ $? -eq 2 ]]; then
    export PYTHONBREAKPOINT="ipython.set_trace"
fi


#!/bin/sh

alias clear_pyc='find . | grep -E "(__pycache__|\.pyc|\.pyo$$)" | xargs rm -rf'
alias clear_empty_dirs='find . -type d -empty -delete'

alias update_packages='pushd ~/.dot-config; make global_update; popd;'
alias update_repos='pushd ~/.dot-config; make vcspull; popd;'

export TTY=$(tty)

alias bench='for i in $(seq 1 10); do /usr/bin//time /bin/zsh -i -c exit; done;'

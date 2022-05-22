#!/bin/sh

alias clear_pyc='find . | grep -E "(__pycache__|\.pyc|\.pyo$$)" | xargs rm -rf'
alias clear_empty_dirs='find . -type d -empty -delete'

# Thank you https://stackoverflow.com/a/1267524
alias my_internal_ip='python -c "import socket; print([l for l in ([ip for ip in socket.gethostbyname_ex(socket.gethostname())[2] if not ip.startswith(\"127.\")][:1], [[(s.connect((\"8.8.8.8\", 53)), s.getsockname()[0], s.close()) for s in [socket.socket(socket.AF_INET, socket.SOCK_DGRAM)]][0][1]]) if l][0][0])"'

alias update_packages='pushd ~/.dot-config; make global_update; popd;'
alias update_repos='pushd ~/.dot-config; make vcspull; popd;'

export TTY=$(tty)

alias glog='git reflog --pretty=short --date=iso'

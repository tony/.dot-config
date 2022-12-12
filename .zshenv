# Ubuntu: Skip the global compinit
skip_global_compinit=1

# Ubuntu: skip /etc/profile.d ubuntu welcome message
export MOTD_SHOWN=1

if [ -d /etc/profile.d ]; then
  for i in /etc/profile.d/*.sh; do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi

if [ -d $HOME/.dot-config/.shell/vars.d/ ]; then
  for i in $HOME/.dot-config/.shell/vars.d/*.sh; do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi

if [ -n XDG_CONFIG_HOME ]; then
  export XDG_CONFIG_HOME="$HOME/.config"
fi

pathprepend() {
    for ARG in "$@"
    do
        if [ -d "$ARG" ] && [[ ":$PATH:" != *":$ARG:"* ]]; then
            PATH="$ARG${PATH:+":$PATH"}"
        fi
    done
}

pathprepend $HOME/bin
pathprepend $HOME/.local/bin

if which yarn 1>/dev/null 2>&1; then
    pathprepend `yarn global bin`
fi

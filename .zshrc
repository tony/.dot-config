### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit's installer chunk

# Functions to make configuration less verbose (thanks https://github.com/zdharma/zinit-configs/)
# zt() : First argument is a wait time and suffix, ie "0a". Anything that doesn't match will be passed as if it were an ice mod. Default ices depth'3' and lucid
zt()  { zinit depth'3' lucid ${1/#[0-9][a-c]/wait"$1"} "${@:2}"; }

# tmux / tmuxp
export DISABLE_AUTO_TITLE='true'

# https://github.com/robbyrussell/oh-my-zsh/issues/5874
export ZSH_CACHE_DIR=$HOME/.zsh

# For poetry: https://github.com/python-poetry/poetry#enable-tab-completion-for-bash-fish-or-zsh
fpath+=~/.zfunc

# additional completions
autoload -U +X compinit && compinit

# ignore hosts completion
zstyle ':completion:*' hosts off

##
## History
###
### Source: https://dustri.org/b/my-zsh-configuration.html
### Also https://github.com/robbyrussell/oh-my-zsh/blob/master/lib/history.zsh
HISTFILE=~/.zsh_history         # where to store zsh config
HISTSIZE=10000                   # big history
SAVEHIST=10000                   # big history
setopt append_history           # append
setopt hist_expire_dups_first
setopt hist_ignore_all_dups     # no duplicate
setopt hist_ignore_space      # ignore space prefixed commands
setopt hist_verify              # show before executing history commands
setopt inc_append_history       # add commands as they are typed, don't wait until shell exit 
setopt share_history            # share hist between sessions

zt for OMZ::lib/history.zsh
PS1="READY > "
zinit ice wait'!0'

zinit snippet OMZ::plugins/history/history.plugin.zsh
zinit snippet OMZ::plugins/git/git.plugin.zsh
# Stuff is slowing me down wtf
# zinit snippet OMZ::plugins/ssh-agent/ssh-agent.plugin.zsh
if [[ "${(%):-%#}" != "#" ]]; then
    # Revert https://github.com/ohmyzsh/ohmyzsh/pull/6309
    # # only if not root
    # zstyle :omz:plugins:ssh-agent agent-forwarding on
    # # [[ -e "$HOME/.ssh/id_ed25519" ]] && zstyle :omz:plugins:ssh-agent identities id_ed25519
    # zstyle :omz:plugins:ssh-agent lazy no
    # zinit ice silent
    # zinit snippet OMZ::plugins/ssh-agent/ssh-agent.plugin.zsh

    # if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    #  ssh-agent -t 1h > "$XDG_RUNTIME_DIR/ssh-agent.env"
    #  fi
    #  if [[ ! "$SSH_AUTH_SOCK" ]]; then
  	# source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
    #  fi

    # Enable keychain
    # Credit: @yous license MIT https://github.com/yous/dotfiles/blob/master/zshrc Accessed 2021-06-13
    if command -v keychain >/dev/null; then
      KEY=''
      if [ -f "$HOME/.ssh/id_ed25519" ]; then
	KEY='id_ed25519'
      elif [ -f "$HOME/.ssh/id_rsa" ]; then
	KEY='id_rsa'
      fi
      if [ -n "$KEY" ]; then
	if [ "$(uname)" = 'Darwin' ]; then
	  eval `keychain --eval --quiet --agents ssh --inherit any $KEY`
	else
	  eval `keychain --eval --quiet --agents ssh $KEY`
	fi
      fi
      unset KEY
    fi
fi

# SPACESHIP_PROMPT_ADD_NEWLINE=false
# SPACESHIP_PACKAGE_SHOW=false
# SPACESHIP_GIT_STATUS_STASHED=''
# SPACESHIP_EXEC_TIME_PREFIX=''
# SPACESHIP_PROMPT_ORDER=(
#   dir           # Current directory section
#   git           # Git section (git_branch + git_status)
#   venv          # virtualenv section
#   exec_time     # Execution time
#   line_sep      # Line break
#   exit_code     # Exit code section
#   char          # Prompt character
# )
# zinit light denysdovhan/spaceship-prompt

# Thanks @rkoder
# https://github.com/rkoder/dotfiles/blob/2d792f9091b33f67a2507b70878a7f575c28b5f0/zsh/rc.d/50-zinit.zsh
if [ "$(uname)" = "Darwin" ]; then
    zinit ice as"program" pick"target/release/starship" \
        atclone"cargo build --release" atpull"%atclone" \
        atload'eval $(starship init zsh)'
else
    zinit ice from"gh-r" as"program" mv"target/*/release/starship -> starship" \
        atload'eval $(starship init zsh)'
fi
zinit light starship/starship

zinit load chrissicool/zsh-256color

zinit load zsh-users/zsh-syntax-highlighting

# Enable completion caching
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# Disable hostname completion, because it's slow
zstyle ':completion:*' hosts off


if command -v reattach-to-user-namespace > /dev/null; then
  alias vim="reattach-to-user-namespace vim"
  alias nvim="reattach-to-user-namespace nvim"
fi

# for OS X keychain(1) error, Error: Problem adding; giving up
# if ! fuser "$SSH_AUTH_SOCK" >/dev/null 2>/dev/null; then
#   # Nothing has the socket open, it means the agent isn't running
#   ssh-agent -a "$SSH_AUTH_SOCK" -s >~/.ssh/agent-info
# fi
fixssh() {
    for key in SSH_AUTH_SOCK SSH_CONNECTION SSH_CLIENT; do
        if (tmux show-environment | grep "^${key}" > /dev/null); then
            value=`tmux show-environment | grep "^${key}" | sed -e "s/^[A-Z_]*=//"`
            export ${key}="${value}"
        fi
    done
}
fixssh()
source ~/.dot-config/.shell/env.d/most.sh
source ~/.dot-config/.shell/env.d/python-breakpoint.sh
source ~/.dot-config/.shell/aliases.sh

pathprepend() {
  for ARG in "$@"
  do
    if [ -d "$ARG" ] && [[ ":$PATH:" != *":$ARG:"* ]]; then
        PATH="$ARG${PATH:+":$PATH"}"
    fi
  done
}

source ~/.dot-config/.shell/paths.d/yarn.sh

zinit light zinit-zsh/z-a-bin-gem-node

# zinit load asdf-vm/asdf
# Credit: https://github.com/xeho91/.dotfiles/blob/172f1d97f6d51af35981b7c87f024244d16d1540/Linux/Zsh/configurations/plugins/programming_languages.zsh
# License: Unlicense
function install_asdf_plugins() {
	local plugins_list_to_install=( \
		# https://github.com/asdf-vm/asdf-nodejs
		nodejs \
		# https://github.com/danhper/asdf-python
		python \
		# https://github.com/code-lever/asdf-rust
		rust \
		# https://github.com/kennyp/asdf-golang
		golang \
	)
	local installed_plugins=$(asdf plugin list)
	for plugin in $plugins_list_to_install; do
		if [[ "$installed_plugins" != *"$plugin"* ]]; then
			command asdf plugin add $plugin
			print -P "%F{blue}Added plugin for %K{white} $plugin %k anod now installing the latest version...%f"
			if [[ "$plugin" == "nodejs" ]]; then
				bash -c "$ASDF_DATA_DIR/plugins/nodejs/bin/import-release-team-keyring"
			fi
                        command asdf install $plugin
			command asdf reshim $plugin
			print -P "%F{green}Finished installing the lastest version with asdf %K{white} $plugin %k%f."
		else
			if [[ "$plugin" == "rust" ]]; then
				zinit \
					id-as"cargo-completion" \
					mv"cargo* -> _cargo" \
					as"completion" \
					for https://github.com/rust-lang/cargo/blob/master/src/etc/_cargo
			fi
		fi
	done
}

# =========================================================================== #
# Asdf-vm - Extendable (v)ersion (m)anager for languages tools
# ------------------------------------------------------------
# https://github.com/asdf-vm/asdf
# =========================================================================== #
zinit \
	id-as"asdf" \
	atinit'export ASDF_DATA_DIR="$XDG_CONFIG_HOME/.asdf"; \
		export ASDF_CONFIG_FILE="$ASDF_DATA_DIR/.asdfrc";
		export ASDF_PYTHON_DEFAULT_PACKAGES_FILE="$ZDOTDIR/.default-python-packages";
		export ASDF_NPM_DEFAULT_PACKAGES_FILE="$ZDOTDIR/.default-npm-packages"' \
	src"asdf.sh" \
	atload'install_asdf_plugins; unfunction install_asdf_plugins' \
	for @asdf-vm/asdf

zinit load zdharma/null

source ~/.dot-config/.shell/env.d/poetry.sh
source ~/.dot-config/.shell/env.d/travis.sh
source ~/.dot-config/.shell/env.d/fzf.sh
source ~/.dot-config/.shell/vars.d/ignore.sh
source ~/.dot-config/.shell/vars.d/fzf.sh

# Binary release in archive, from GitHub-releases page.
# After automatic unpacking it provides program "fzf".
zinit ice from"gh-r" as"program"
zinit load junegunn/fzf


zplugin ice wait"1" lucid

[ -f ~/.zshrc.local ] && source ~/.zshrc.local
[ -f ~/.profile ] && source ~/.profile

export DOCKER_HOST=unix:///run/user/1000/docker.sock

pathprepend $HOME/bin
pathprepend $HOME/.local/bin

export SAM_CLI_TELEMETRY=0

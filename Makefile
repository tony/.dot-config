DOT_CONFIG_DIR=~/.dot-config

make lint:
	shellcheck -s sh \.shell/**/*.sh

antigen:
	curl -L git.io/antigen > ${DOT_CONFIG_DIR}/antigen.zsh

install:
	$(MAKE) antigen

	ln -si ${DOT_CONFIG_DIR}/.tmux/ ~/.tmux
	ln -si ~/.tmux/.tmux.conf ~/.tmux.conf
	ln -si ${DOT_CONFIG_DIR}/.vim/ ~/.vim
	ln -si ${DOT_CONFIG_DIR}/.fonts/ ~/.fonts
	ln -si ${DOT_CONFIG_DIR}/.gitconfig ~/.gitconfig
	ln -si ${DOT_CONFIG_DIR}/.gitignore_global ~/.gitignore_global
	ln -si ${DOT_CONFIG_DIR}/.zshrc ~/.zshrc
	ln -si ${DOT_CONFIG_DIR}/.vcspull ~/.vcspull
	ln -si ${DOT_CONFIG_DIR}/.vcspull.yaml ~/.vcspull.yaml
	ln -si ${DOT_CONFIG_DIR}/.Xresources ~/.Xresources
	ln -si ${DOT_CONFIG_DIR}/.ipython ~/.ipython
	ln -si ${DOT_CONFIG_DIR}/.ptpython ~/.ptpython

debian_fix_inotify:
	# Fixes inotify for watchman
	echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

debian_packages:
	sudo apt-get install tmux cmake ninja-build rxvt-unicode-256color libpython-dev \
	cowsay \
	fortune-mod \
	vim-nox \
	ctags \
	silversearcher-ag \
	wget \
	git \
	tig \
	keychain \
	most \
	entr \
	curl \
	openssh-server \
	build-essential \
	pgadmin3 \
	postgresql-11 \
	htop \
	fonts-noto-cjk \
	xfonts-wqy libpython3.7-dev python3-pip libsasl2-dev libxslt1-dev libxmlsec1-dev libxml2-dev libldap2-dev tmux redis-server pkg-config libtool m4 automake autoconf

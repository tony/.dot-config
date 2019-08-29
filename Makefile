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
	echo fs.inotify.max_user_watches=1524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

debian_packages:
	sudo apt-get install \
	tmux \
	rsync \
	cmake ninja-build \
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
	postgresql \
	htop \
	redis-server \
	libpython3.7-dev python3-pip libpython-dev \
	libsasl2-dev libxslt1-dev libxmlsec1-dev libxml2-dev libldap2-dev \
	build-essential \
	pkg-config libtool m4 automake autoconf \
	zsh

debian_packages_x11:
	sudo apt install \
	pgadmin3 \
	kitty \
	fonts-noto-cjk xfonts-wqy \
	rxvt-unicode-256color

debian_node:
	curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -

ubuntu_geary:
	sudo add-apt-repository ppa:geary-team/releases

pip_packages:
	pip install --user -U \
	python-language-server \
	virtualenv \
	pip \
	pipenv \
	tmuxp \
	vcspull \
	dotfiles \
	spotdl

remove_civ6_harassing_intro:
	cd ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ VI/steamassets/base/platforms/windows/movies/; \
	mv logos.bk2 logos.bk2.backup; \
	mv bink2_aspyr_logo_black_white_1080p_30fps.bk2 bink2_aspyr_logo_black_white_1080p_30fps.bk2.backup;

fix_linux_time_dualboot:
	timedatectl set-local-rtc 1 --adjust-system-clock

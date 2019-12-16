DOT_CONFIG_DIR=~/.dot-config
PIPX_PACKAGES=python-language-server virtualenv pipenv tmuxp vcspull dotfiles spotdl black isort

make lint:
	shellcheck -s sh \.shell/**/*.sh

antigen:
	curl -L git.io/antigen > ${DOT_CONFIG_DIR}/antigen.zsh

install:
	$(MAKE) antigen

	ln -si ${DOT_CONFIG_DIR}/.tmux/ ~
	ln -si ~/.tmux/.tmux.conf ~
	ln -si ${DOT_CONFIG_DIR}/.vim/ ~
	ln -si ${DOT_CONFIG_DIR}/.fonts/ ~
	ln -si ${DOT_CONFIG_DIR}/.gitconfig ~/.gitconfig
	ln -si ${DOT_CONFIG_DIR}/.gitignore_global ~/.gitignore_global
	ln -si ${DOT_CONFIG_DIR}/.zshrc ~/.zshrc
	ln -si ${DOT_CONFIG_DIR}/.vcspull ~
	ln -si ${DOT_CONFIG_DIR}/.vcspull.yaml ~/.vcspull.yaml
	ln -si ${DOT_CONFIG_DIR}/.Xresources ~/.Xresources
	ln -si ${DOT_CONFIG_DIR}/.ipython ~
	ln -si ${DOT_CONFIG_DIR}/.ptpython ~
	ln -si ${DOT_CONFIG_DIR}/.zfunc/ ~

poetry:
	python3 -m pip install --user poetry
	ln -sf ${DOT_CONFIG_DIR}/.zfunc/ ~
	poetry completions zsh > ~/.zfunc/_poetry

debian_fix_inotify:
	# Fixes inotify for watchman
	grep -qxF 'fs.inotify.max_user_watches=1524288' /etc/sysctl.conf || echo 'fs.inotify.max_user_watches=1524288' | sudo tee -a /etc/sysctl.conf
	sudo sysctl -p

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
	htop \
	redis-server \
	libpython-dev \
	python3.8 python3.8-dev python3.8-venv python3.8-dbg \
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

debian_postgres:
	wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
	echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
	sudo apt update
	sudo apt -y install postgresql-12 postgresql-client-12 postgresql-server-dev-12

pip_install:
	python3.8 -m pip install pip

pip_install_packages:
	pip install --user -U ${PIPX_PACKAGES}

pip_uninstall_packages:
	pip uninstall -y ${PIPX_PACKAGES}

pipx_install:
	python3 -m pip install pipx

pipx_install_packages:
	for pkg in ${PIPX_PACKAGES}; do \
		pipx install $$pkg; \
	done

pipx_upgrade_packages:
	for pkg in ${PIPX_PACKAGES}; do \
		pipx upgrade $$pkg; \
	done

remove_civ6_harassing_intro:
	cd ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ VI/steamassets/base/platforms/windows/movies/; \
	mv logos.bk2 logos.bk2.backup; \
	mv bink2_aspyr_logo_black_white_1080p_30fps.bk2 bink2_aspyr_logo_black_white_1080p_30fps.bk2.backup;

fix_linux_time_dualboot:
	timedatectl set-local-rtc 1 --adjust-system-clock

vcspull:
	vcspull \
	libtmux \
	tmuxp \
	libvcs \
	vcspull \
	unihan-db \
	unihan-etl \
	cihai \
	cihai-cli


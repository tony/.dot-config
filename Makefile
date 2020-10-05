SHELL=/bin/bash
DOT_CONFIG_DIR=~/.dot-config
PIP_PACKAGES=python-language-server black 'isort<5' virtualenv pipenv tmuxp vcspull dotfiles spotdl

make lint:
	shellcheck -s sh \.shell/**/*.sh

install:
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
	mkdir -p ~/.ssh
	ln -si ${DOT_CONFIG_DIR}/.ssh/config ~/.ssh/config

debian_fix_inotify:
	# Fixes inotify for watchman
	grep -qxF 'fs.inotify.max_user_watches=1524288' /etc/sysctl.conf || echo 'fs.inotify.max_user_watches=1524288' | sudo tee -a /etc/sysctl.conf
	sudo sysctl -p

debian_fix_docker:
	sudo usermod -aG docker $$USER

debian_pyenv_packages:
	sudo apt-get update; \
	sudo apt-get install --no-install-recommends \
	make \
	build-essential \
	libssl-dev \
	zlib1g-dev \
	libbz2-dev \
	libreadline-dev \
	libsqlite3-dev \
	wget \
	curl \
	llvm \
	libncurses5-dev \
	xz-utils \
	tk-dev \
	libxml2-dev \
	libxmlsec1-dev \
	libffi-dev \
	liblzma-dev

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
	most \
	entr \
	curl \
	openssh-server \
	htop \
	redis-server \
	libpython2-dev \
	python3-venv python3 python3-dev python3-venv python3-dbg \
	python3.8-venv python3.8 python3.8-dev python3.8-venv python3.8-dbg \
	libsasl2-dev libxslt1-dev libxmlsec1-dev libxml2-dev libldap2-dev \
	libffi-dev libsqlite3-dev libreadline-dev libbz2-dev \
	build-essential \
	pkg-config libtool m4 automake autoconf \
	zsh

debian_packages_x11:
	sudo apt install \
	pgadmin3 \
	kitty \
	fonts-noto-cjk xfonts-wqy \
	fonts-cascadia-code \
	rxvt-unicode-256color \
	nitrogen \
	scrot \
	maim \
	slop

debian_vim:
	sudo add-apt-repository 'ppa:jonathonf/vim'

debian_node:
	curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -

ubuntu_geary:
	sudo add-apt-repository ppa:geary-team/releases

ubuntu_peek: 
	sudo add-apt-repository ppa:peek-developers/stable
	sudo apt update && sudo apt install peek

ubuntu_i3:
	sudo /usr/lib/apt/apt-helper download-file https://debian.sur5r.net/i3/pool/main/s/sur5r-keyring/sur5r-keyring_2020.02.03_all.deb keyring.deb SHA256:c5dd35231930e3c8d6a9d9539c846023fe1a08e4b073ef0d2833acd815d80d48
	sudo dpkg -i ./keyring.deb
	sudo echo "deb https://debian.sur5r.net/i3/ `grep '^DISTRIB_CODENAME=' /etc/lsb-release | cut -f2 -d=)` universe" | sudo tee /etc/apt/sources.list.d/sur5r-i3.list
	sudo apt update
	sudo apt install i3

debian_postgres:
	wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
	echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
	sudo apt update
	sudo apt -y install postgresql-12 postgresql-client-12 postgresql-server-dev-12

pip_install:
	python3.8 -m pip install pip

pip_install_packages:
	pip install --user -U pip
	pip install --user -U ${PIP_PACKAGES}
	$(MAKE) poetry

pip_uninstall_packages:
	pip uninstall -y ${PIP_PACKAGES}

# pip_upgrade_packages:
# 	for pkg in ${PIPX_PACKAGES}; do \
# 		pip install -U --user $$pkg; \
# 	done

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

debian_disable_mpd:
	sudo update-rc.d mpd disable
	sudo systemctl disable mpd.socket

test_fzf_default_command:
	eval $${FZF_DEFAULT_COMMAND}

debian_update:
	sudo apt update && sudo apt full-upgrade

yarn_set_prefix:
	yarn config set prefix ~/.yarn  # So node_modules/yarn.lock doesn't get created everywhere

yarn_add_packages:
	$(MAKE) yarn_set_prefix
	yarn global add bower browserify brunch foreman nodemon npm-check-updates create-next-app gatsby-cli bibtex-tidy lerna

yarn_upgrade_packages:
	$(MAKE) yarn_set_prefix
	yarn global upgrade bower browserify brunch foreman nodemon npm-check-updates create-next-app gatsby-cli bibtex-tidy lerna

yarn_remove_packages:
	yarn global remove bower browserify brunch foreman nodemon npm-check-updates create-next-app gatsby-cli bibtex-tidy lerna

npm_uninstall_packages:
	sudo npm uninstall -g bower browserify brunch foreman nodemon npm-check-updates create-next-app gatsby-cli bibtex-tidy lerna
	npm uninstall -g bower browserify brunch foreman nodemon npm-check-updates create-next-app gatsby-cli bibtex-tidy lerna
	npm uninstall bower browserify brunch foreman nodemon npm-check-updates create-next-app gatsby-cli bibtex-tidy lerna

global_update:
	$(MAKE) debian_update
	$(MAKE) pip_install_packages  # Handles upgrades
	$(MAKE) yarn_upgrade_packages

update_gatsby_sites:
	pushd ~/work/parataxic.org; git pull --rebase --autostash; popd; \
	pushd ~/work/develtech; git pull --rebase --autostash; popd; \
	pushd ~/work/hsk-django; git pull --rebase --autostash; popd;

debian_wsl2_chrome:
	wget 'https://github.com/webnicer/chrome-downloads/blob/master/x64.deb/google-chrome-stable_85.0.4183.121-1_amd64.deb?raw=true'
	wget http://chromedriver.storage.googleapis.com/85.0.4183.87/chromedriver_linux64.zip
	unzip chromedriver_linux64.zip
	sudo ln -sf $PWD/chromedriver /usr/local/bin/chromedriver

configure_wsl2_vcxsrv:
	export DISPLAY=$(grep -m 1 nameserver /etc/resolv.conf | awk '{print $2}'):0.0

debian_python:
	wget https://bootstrap.pypa.io/get-pip.py
	python3 get-pip.py
	rm get-pip.py
	# pyenv is installed by zinit
	# curl https://pyenv.run | bash
	$(MAKE) debian_pyenv_packages
	pyenv install 3.7.8
	pyenv global 3.7.8
	$(MAKE) poetry_install

poetry_install:
	curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
	ln -sf ${DOT_CONFIG_DIR}/.zfunc/ ~
	poetry completions zsh > ~/.zfunc/_poetry

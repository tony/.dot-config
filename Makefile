SHELL=/bin/bash
DOT_CONFIG_DIR=~/.dot-config
PIP_PACKAGES=python-language-server virtualenv pipenv tmuxp vcspull dotfiles spotdl ptpython git-sweep
NPM_PACKAGES=npm-check-updates gatsby-cli lerna @angular/cli
SH_FILES= find . -type f -not -path '*/\.vim*' -and -not -path '*/\.git*' -and -not -path '*/.tmux*' -and -not -path '*/config/base16\-shell*' -and -not -path '*\.shell/prompt/git\-prompt\.sh' | grep -i '.*[.]\(z\)\?sh$$\|[.]zsh.*$$' 2> /dev/null
# Unused packages: browserify nodemon create-next-app bibtex-tidy @microsoft/rush pnpm @nrwl/workspace @nrwl/react

lint:
	shellcheck -s sh \.shell/**/*.sh

fmt:
	beautysh `${SH_FILES}`

install:
	ln -si ${DOT_CONFIG_DIR}/.tmux/ ~
	ln -si ~/.tmux/.tmux.conf ~
	ln -si ${DOT_CONFIG_DIR}/.vim/ ~
	ln -si ${DOT_CONFIG_DIR}/.fonts/ ~
	ln -si ${DOT_CONFIG_DIR}/.gitconfig ~/.gitconfig
	ln -si ${DOT_CONFIG_DIR}/.gitignore_global ~/.gitignore_global
	ln -si ${DOT_CONFIG_DIR}/.zshrc ~/.zshrc
	ln -si ${DOT_CONFIG_DIR}/.zshenv ~/.zshenv
	ln -si ${DOT_CONFIG_DIR}/.asdfrc ~/.asdfrc
	ln -si ${DOT_CONFIG_DIR}/.tool-versions ~/.tool-versions
	ln -si ${DOT_CONFIG_DIR}/.vcspull ~
	ln -si ${DOT_CONFIG_DIR}/.vcspull.yaml ~/.vcspull.yaml
	ln -si ${DOT_CONFIG_DIR}/.Xresources ~/.Xresources
	ln -si ${DOT_CONFIG_DIR}/.ipython ~
	ln -si ${DOT_CONFIG_DIR}/.ptpython ~
	ln -si ${DOT_CONFIG_DIR}/.zfunc/ ~
	ln -si ${DOT_CONFIG_DIR}/.tmux/ ~
	ln -si ${DOT_CONFIG_DIR}/.tmuxp/ ~
	ln -si ${DOT_CONFIG_DIR}/.zsh_plugins.txt ~
	ln -si ${DOT_CONFIG_DIR}/.dotfilesrc ~
	mkdir -p ~/.ssh
	ln -si ${DOT_CONFIG_DIR}/.ssh/config ~/.ssh/config

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
	libncurses-dev \
	xz-utils \
	tk-dev \
	libxml2-dev \
	libxmlsec1-dev \
	libffi-dev \
	liblzma-dev \
	libpython3-all-dev

debian_packages:
	sudo apt-get install \
	unzip \
	wget \
	tmux \
	rsync \
	cmake ninja-build \
	cowsay \
	fortune-mod \
	vim-nox \
	universal-ctags \
	silversearcher-ag \
	git \
	tig \
	most \
	entr \
	curl \
	keychain \
	openssh-server \
	htop \
	ccls \
	redis-server \
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
	slop \
	gammastep

ubuntu_peek: 
	sudo add-apt-repository ppa:peek-developers/stable
	sudo apt update && sudo apt install peek

ubuntu_git:
	sudo add-apt-repository ppa:git-core/ppa
	sudo apt update && sudo apt install git

ubuntu_i3:
	sudo /usr/lib/apt/apt-helper download-file https://debian.sur5r.net/i3/pool/main/s/sur5r-keyring/sur5r-keyring_2020.02.03_all.deb keyring.deb SHA256:c5dd35231930e3c8d6a9d9539c846023fe1a08e4b073ef0d2833acd815d80d48
	sudo dpkg -i ./keyring.deb
	sudo echo "deb https://debian.sur5r.net/i3/ `grep '^DISTRIB_CODENAME=' /etc/lsb-release | cut -f2 -d=)` universe" | sudo tee /etc/apt/sources.list.d/sur5r-i3.list
	sudo apt update
	sudo apt install i3

ubuntu_sway:
	sudo apt install swayidle swaybg sway-backgrounds sway swaylock \
		wofi

pip_install:
	# python3.8 -m pip install pip
	curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py

pip_install_packages:
	pip install --user -U ${PIP_PACKAGES}

pip_uninstall_packages:
	pip uninstall -y ${PIP_PACKAGES}

cargo_install:
	cargo install \
		gitui \
		hyperfine \
		dprint

fix_linux_time_dualboot:
	timedatectl set-local-rtc 1 --adjust-system-clock

vcspull:
	vcspull sync \
	libtmux \
	tmuxp \
	libvcs \
	vcspull \
	g \
	gp-libs \
	unihan-db \
	unihan-etl \
	cihai \
	cihai-cli \
	django-slugify-processor \
	django-docutils \
	website

debian_disable_mpd:
	sudo update-rc.d mpd disable
	sudo systemctl disable mpd.socket

test_fzf_default_command:
	eval $${FZF_DEFAULT_COMMAND}

debian_update:
	sudo apt update && sudo apt upgrade

yarn_set_prefix:
	yarn config set prefix ~/.yarn  # So node_modules/yarn.lock doesn't get created everywhere

yarn_add_packages:
	$(MAKE) yarn_set_prefix
	yarn global add ${NPM_PACKAGES}

yarn_upgrade_packages:
	$(MAKE) yarn_set_prefix
	yarn global upgrade ${NPM_PACKAGES}

yarn_remove_packages:
	yarn global remove ${NPM_PACKAGES}

npm_uninstall_packages:
	sudo npm uninstall -g ${NPM_PACKAGES}
	npm uninstall -g ${NPM_PACKAGES}
	npm uninstall ${NPM_PACKAGES}

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
	sudo mv $$PWD/chromedriver /usr/local/bin/chromedriver

debian_wsl_puppeteer:
	sudo apt install libatk-adaptor libnss3 libcups2 libxkbcommon0 libgtk-3-0 libgbm1

debian_elasticsearch:
	wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
	sudo apt-get install apt-transport-https
	echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
	sudo apt-get update && sudo apt-get install elasticsearch

configure_wsl2_vcxsrv:
	export DISPLAY=$(grep -m 1 nameserver /etc/resolv.conf | awk '{print $2}'):0.0

linux_aws_sam:
	wget https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip
	unzip aws-sam-cli-linux-x86_64.zip -d sam-installation
	sudo ./sam-installation/install

debian_python:
	wget https://bootstrap.pypa.io/get-pip.py
	python3 get-pip.py
	rm get-pip.py
	# pyenv is installed by zinit
	# curl https://pyenv.run | bash
	$(MAKE) debian_pyenv_packages

poetry_install:
	curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python - --version 1.0.10 --no-modify-path
	ln -sf ${DOT_CONFIG_DIR}/.zfunc/ ~
	poetry completions zsh > ~/.zfunc/_poetry
	poetry self update 1.0.10

gh_cli:
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
	sudo apt-add-repository https://cli.github.com/packages
	sudo apt update
	sudo apt install gh

travis_cli:
	sudo gem install travis --no-document

sentry_cli:
	curl -sL https://sentry.io/get-cli/ | bash

wine_kindle_fix:
	# Credit: https://twitter.com/sagawa_aki/status/1360561626718474240
	# mkdir -p ${WINEPREFIX:-$HOME/.wine}/drive_c/users/$USER/AppData/Local/Amazon/Kindle
	mkdir -p ${HOME}/.wine/drive_c/users/${USER}/AppData/Local/Amazon/Kindle
	# wine reg add 'HKLM\Software\Microsoft\Windows NT\CurrentVersion\FontSubstitutes' /v "MS Shell Dlg 2" /f /d "Ume UI Gothic"

download_kindle:
	wget --trust-server-names https://www.amazon.com/kindlepcdownload/ref=klp_hz_win

winegecko:
	# This is for wine 5.x
	# https://unix.stackexchange.com/a/627495
	wget http://dl.winehq.org/wine/wine-gecko/2.47.1/wine-gecko-2.47.1-x86.msi
	wine msiexec /i wine-gecko-2.47.1-x86.msi

	wget http://dl.winehq.org/wine/wine-gecko/2.47.1/wine-gecko-2.47.1-x86_64.msi
	wine msiexec /i wine-gecko-2.47.1-x86_64.msi

debian_gecko:
	# dependency
	sudo apt install winbind

ubuntu_wine:
	sudo dpkg --add-architecture i386 
	wget https://dl.winehq.org/wine-builds/Release.key
	sudo apt-key add Release.key
	sudo apt-add-repository 'https://dl.winehq.org/wine-builds/ubuntu/'

debian_clangd:
	sudo apt install clangd-13
	sudo update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-13 100

wine_kindle:
	wine ~/.wine/drive_c/Program\ Files\ \(x86\)/Amazon/Kindle/Kindle.exe

winget_export_packages:
	winget.exe export -o ~/.dot-config/os/w11/winget-packages.json

winget_import_packages:
	winget.exe import -i ~/.dot-config/os/w11/winget-packages.json

wsl_shortcuts:
	# When using intercop.appendWindowsPath = false, this makes sure those paths are available again
	ln -sf `wslpath C:/Windows/System32/wsl.exe` ~/.local/bin/wsl
	ln -sf `wslpath C:/Windows/System32/wsl.exe` ~/.local/bin/wsl.exe
	ln -sf `wslpath \`wslvar USERPROFILE\`"\AppData\Local\Microsoft\WindowsApps\winget.exe"` ~/.local/bin/winget.exe
	ln -sf `wslpath \`wslvar USERPROFILE\`"\AppData\Local\Microsoft\WindowsApps\winget.exe"` ~/.local/bin/winget
	ln -sf `wslpath C:/Windows/System32/notepad.exe` ~/.local/bin/notepad.exe
	ln -sf `wslpath C:/Windows/System32/notepad.exe` ~/.local/bin/notepad
	ln -sf `wslpath C:/Windows/explorer.exe` ~/.local/bin/explorer.exe
	ln -sf `wslpath C:/Windows/explorer.exe` ~/.local/bin/explorer
	ln -sf `wslpath \`wslvar USERPROFILE\``/AppData/Local/Programs/Microsoft\ VS\ Code/code.exe ~/.local/bin/code.exe
	ln -sf `wslpath \`wslvar USERPROFILE\``/AppData/Local/Programs/Microsoft\ VS\ Code/code.exe ~/.local/bin/code

asdf_plugins_install:
	cut -d' ' -f1 .tool-versions|xargs -I '{}' asdf plugin add '{}'

asdf_install_with_nodejs_mirror:
	env NODEJS_ORG_MIRROR=https://mirrors.dotsrc.org/nodejs/release/ asdf install

htoprc_ignore_changes:
	git update-index --assume-unchanged config/htop/htoprc

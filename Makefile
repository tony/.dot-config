##########################################################
# Makefile for Various DevOps / Dotfiles Setup Tasks
##########################################################

# Use a more portable shell invocation:
SHELL = /usr/bin/env bash

# Where dot-config files live:
DOT_CONFIG_DIR ?= $(HOME)/.dot-config

# Define lists of packages upfront for easier editing/maintenance
PIP_PACKAGES = python-language-server virtualenv pipenv tmuxp vcspull dotfiles \
               spotdl ptpython git-sweep

NPM_PACKAGES = npm-check-updates gatsby-cli lerna @angular/cli

# Deb/Ubuntu general packages
DEBIAN_PACKAGES = unzip wget tmux rsync cmake ninja-build cowsay fortune-mod \
                  vim-nox universal-ctags silversearcher-ag git tig most entr \
                  curl keychain openssh-server htop ccls redis-server \
                  libsasl2-dev libxslt1-dev libxmlsec1-dev libxml2-dev \
                  libldap2-dev libffi-dev libsqlite3-dev libreadline-dev \
                  libbz2-dev build-essential pkg-config libtool m4 automake \
                  autoconf zsh

# Deb/Ubuntu X11 packages
DEBIAN_PACKAGES_X11 = pgadmin3 kitty fonts-noto-cjk xfonts-wqy fonts-cascadia-code \
                      rxvt-unicode-256color nitrogen scrot maim slop gammastep

# Deb/Ubuntu packages for pyenv building
DEBIAN_PYENV_BUILD_PKGS = make build-essential libssl-dev zlib1g-dev libbz2-dev \
                          libreadline-dev libsqlite3-dev wget curl llvm libncurses-dev \
                          xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev \
                          liblzma-dev libpython3-all-dev

# Shell script locator for fmt target
SH_FILES := find . \
  -type f \
  -not -path '*/.vim*' \
  -not -path '*/.git*' \
  -not -path '*/.tmux*' \
  -not -path '*/config/base16-shell*' \
  -not -path '*\.shell/prompt/git-prompt\.sh' \
  | grep -i '.*[.]\(z\)\?sh$$\|[.]zsh.*$$' 2> /dev/null

# .PHONY is crucial so that these targets always run even if a file/folder with same name exists
.PHONY: help lint fmt install debian_packages debian_packages_x11 debian_pyenv_packages \
        ubuntu_peek ubuntu_git ubuntu_i3 ubuntu_sway pip_install pip_install_packages \
        pip_uninstall_packages cargo_install fix_linux_time_dualboot vcspull \
        debian_disable_mpd test_fzf_default_command debian_update yarn_set_prefix \
        yarn_add_packages yarn_upgrade_packages yarn_remove_packages npm_uninstall_packages \
        global_update update_gatsby_sites debian_wsl2_chrome debian_wsl_puppeteer \
        debian_elasticsearch configure_wsl2_vcxsrv linux_aws_sam debian_python poetry_install \
        gh_cli travis_cli sentry_cli wine_kindle_fix download_kindle winegecko debian_gecko \
        ubuntu_wine debian_clangd wine_kindle winget_export_packages winget_import_packages \
        wsl_shortcuts asdf_plugins_install asdf_install_with_nodejs_mirror htoprc_ignore_changes

##########################################################
# Primary, top-level targets
##########################################################

help:
	@echo "Available Targets:"
	@echo "  lint                - Run shellcheck on shell scripts in .shell/"
	@echo "  fmt                 - Format *.sh/*.zsh files using beautysh"
	@echo "  install             - Symlink dot-config files into \$HOME"
	@echo "  debian_packages     - Install common Debian/Ubuntu packages"
	@echo "  debian_packages_x11 - Install extra X11 environment packages"
	@echo "  debian_pyenv_packages - Install system deps needed for pyenv"
	@echo "  pip_install         - Download get-pip.py"
	@echo "  pip_install_packages- Install Python packages via pip"
	@echo "  pip_uninstall_packages - Uninstall Python packages"
	@echo "  cargo_install       - Install cargo-based tools (gitui, hyperfine, ...)"
	@echo "  yarn_add_packages   - Install global Yarn packages"
	@echo "  yarn_upgrade_packages - Upgrade global Yarn packages"
	@echo "  yarn_remove_packages  - Remove global Yarn packages"
	@echo "  npm_uninstall_packages- Uninstall global NPM packages"
	@echo "  global_update       - Update system, pip packages, Yarn packages"
	@echo "  ... (etc. see Makefile for full list) ..."

lint:
	shellcheck -s sh .shell/**/*.sh

fmt:
	# Using backticks for command substitution in Make can be tricky, so we use a variable.
	# Also note that $(SH_FILES) is a variable that calls 'find/grep' at runtime.
	beautysh `$(SH_FILES)`

install:
	# Symlink dot-config files into $HOME
	ln -si $(DOT_CONFIG_DIR)/.tmux/ ~
	ln -si ~/.tmux/.tmux.conf ~
	ln -si $(DOT_CONFIG_DIR)/.vim/ ~
	ln -si $(DOT_CONFIG_DIR)/.fonts/ ~
	ln -si $(DOT_CONFIG_DIR)/.gitconfig ~/.gitconfig
	ln -si $(DOT_CONFIG_DIR)/.gitignore_global ~/.gitignore_global
	ln -si $(DOT_CONFIG_DIR)/.zshrc ~/.zshrc
	ln -si $(DOT_CONFIG_DIR)/.zshenv ~/.zshenv
	ln -si $(DOT_CONFIG_DIR)/.asdfrc ~/.asdfrc
	ln -si $(DOT_CONFIG_DIR)/.tool-versions ~/.tool-versions
	ln -si $(DOT_CONFIG_DIR)/.vcspull ~
	ln -si $(DOT_CONFIG_DIR)/.vcspull.yaml ~/.vcspull.yaml
	ln -si $(DOT_CONFIG_DIR)/.Xresources ~/.Xresources
	ln -si $(DOT_CONFIG_DIR)/.ipython ~
	ln -si $(DOT_CONFIG_DIR)/.ptpython ~
	ln -si $(DOT_CONFIG_DIR)/.tmux/ ~
	ln -si $(DOT_CONFIG_DIR)/.tmuxp/ ~
	ln -si $(DOT_CONFIG_DIR)/.zsh_plugins.txt ~
	ln -si $(DOT_CONFIG_DIR)/.dotfilesrc ~
	mkdir -p ~/.ssh
	ln -si $(DOT_CONFIG_DIR)/.ssh/config ~/.ssh/config
	mkdir -p ~/.config
	ln -si $(DOT_CONFIG_DIR)/config/sheldon/ ~/.config/sheldon


##########################################################
# Debian/Ubuntu-based system targets
##########################################################

debian_pyenv_packages:
	sudo apt-get update
	sudo apt-get install --no-install-recommends $(DEBIAN_PYENV_BUILD_PKGS)

debian_packages:
	sudo apt-get update
	sudo apt-get install $(DEBIAN_PACKAGES)

debian_packages_x11:
	sudo apt-get update
	sudo apt-get install $(DEBIAN_PACKAGES_X11)

ubuntu_i3:
	sudo /usr/lib/apt/apt-helper download-file https://debian.sur5r.net/i3/pool/main/s/sur5r-keyring/sur5r-keyring_2020.02.03_all.deb keyring.deb \
	  SHA256:c5dd35231930e3c8d6a9d9539c846023fe1a08e4b073ef0d2833acd815d80d48
	sudo dpkg -i ./keyring.deb
	echo "deb https://debian.sur5r.net/i3/ $$(grep '^DISTRIB_CODENAME=' /etc/lsb-release | cut -f2 -d=) universe" | sudo tee /etc/apt/sources.list.d/sur5r-i3.list
	sudo apt update
	sudo apt install i3

ubuntu_sway:
	sudo apt install swayidle swaybg sway-backgrounds sway swaylock wofi

debian_update:
	sudo apt update && sudo apt upgrade

debian_disable_mpd:
	sudo update-rc.d mpd disable
	sudo systemctl disable mpd.socket

##########################################################
# Python & pip
##########################################################

pip_install:
	# Download get-pip.py
	curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py

pip_install_packages:
	pip install --user -U $(PIP_PACKAGES)

pip_uninstall_packages:
	pip uninstall -y $(PIP_PACKAGES)

debian_python:
	wget https://bootstrap.pypa.io/get-pip.py
	python3 get-pip.py
	rm get-pip.py
	# pyenv is installed by zinit
	# curl https://pyenv.run | bash
	$(MAKE) debian_pyenv_packages

poetry_install:
	curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python - --version 1.0.10 --no-modify-path
	ln -sf $(DOT_CONFIG_DIR)/.zfunc/ ~
	poetry completions zsh > ~/.zfunc/_poetry
	poetry self update 1.0.10

##########################################################
# Git / VCS
##########################################################

vcspull:
	vcspull sync libtmux tmuxp libvcs vcspull g gp-libs unihan-db unihan-etl cihai cihai-cli \
	            django-slugify-processor django-docutils website

ubuntu_git:
	sudo add-apt-repository ppa:git-core/ppa
	sudo apt update && sudo apt install git

##########################################################
# Cargo / Rust tools
##########################################################

cargo_install:
	cargo install gitui hyperfine dprint

##########################################################
# Node / Yarn / NPM
##########################################################

yarn_set_prefix:
	yarn config set prefix $(HOME)/.yarn  # Prevent node_modules/yarn.lock from scattering

yarn_add_packages:
	$(MAKE) yarn_set_prefix
	yarn global add $(NPM_PACKAGES)

yarn_upgrade_packages:
	$(MAKE) yarn_set_prefix
	yarn global upgrade $(NPM_PACKAGES)

yarn_remove_packages:
	yarn global remove $(NPM_PACKAGES)

npm_uninstall_packages:
	sudo npm uninstall -g $(NPM_PACKAGES)
	npm uninstall -g $(NPM_PACKAGES)
	npm uninstall $(NPM_PACKAGES)

##########################################################
# Combined or multi-step updates
##########################################################

global_update:
	$(MAKE) debian_update
	$(MAKE) pip_install_packages
	$(MAKE) yarn_upgrade_packages

update_gatsby_sites:
	pushd ~/work/parataxic.org; git pull --rebase --autostash; popd
	pushd ~/work/develtech; git pull --rebase --autostash; popd
	pushd ~/work/hsk-django; git pull --rebase --autostash; popd

##########################################################
# Misc Tools / Installs
##########################################################

test_fzf_default_command:
	eval $${FZF_DEFAULT_COMMAND}

fix_linux_time_dualboot:
	timedatectl set-local-rtc 1 --adjust-system-clock

##########################################################
# Extra apt installs / special instructions
##########################################################

ubuntu_wine:
	sudo dpkg --add-architecture i386
	wget https://dl.winehq.org/wine-builds/Release.key
	sudo apt-key add Release.key
	sudo apt-add-repository 'https://dl.winehq.org/wine-builds/ubuntu/'

debian_clangd:
	sudo apt install clangd-13
	sudo update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-13 100

debian_elasticsearch:
	wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
	sudo apt-get install apt-transport-https
	echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
	sudo apt-get update && sudo apt-get install elasticsearch

ubuntu_peek:
	sudo add-apt-repository ppa:peek-developers/stable
	sudo apt update && sudo apt install peek

gh_cli:
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
	sudo apt-add-repository https://cli.github.com/packages
	sudo apt update
	sudo apt install gh

travis_cli:
	sudo gem install travis --no-document

sentry_cli:
	curl -sL https://sentry.io/get-cli/ | bash

##########################################################
# WSL2-Specific / Windows Interop
##########################################################

configure_wsl2_vcxsrv:
	export DISPLAY=$$(grep -m 1 nameserver /etc/resolv.conf | awk '{print $$2}'):0.0

winget_export_packages:
	winget.exe export -o $(HOME)/.dot-config/os/w11/winget-packages.json

winget_import_packages:
	winget.exe import -i $(HOME)/.dot-config/os/w11/winget-packages.json

wsl_shortcuts:
	# When using interop.appendWindowsPath = false, re-add essential Win paths
	ln -sf $$(wslpath 'C:/Windows/System32/wsl.exe') $(HOME)/.local/bin/wsl
	ln -sf $$(wslpath 'C:/Windows/System32/wsl.exe') $(HOME)/.local/bin/wsl.exe
	ln -sf $$(wslpath "$$(wslvar USERPROFILE)"/AppData/Local/Microsoft/WindowsApps/winget.exe) $(HOME)/.local/bin/winget.exe
	ln -sf $$(wslpath "$$(wslvar USERPROFILE)"/AppData/Local/Microsoft/WindowsApps/winget.exe) $(HOME)/.local/bin/winget
	ln -sf $$(wslpath 'C:/Windows/System32/notepad.exe') $(HOME)/.local/bin/notepad.exe
	ln -sf $$(wslpath 'C:/Windows/System32/notepad.exe') $(HOME)/.local/bin/notepad
	ln -sf $$(wslpath 'C:/Windows/explorer.exe') $(HOME)/.local/bin/explorer.exe
	ln -sf $$(wslpath 'C:/Windows/explorer.exe') $(HOME)/.local/bin/explorer
	ln -sf "$$(wslpath "$$(wslvar USERPROFILE)")/AppData/Local/Programs/Microsoft VS Code/code.exe" $(HOME)/.local/bin/code.exe
	ln -sf "$$(wslpath "$$(wslvar USERPROFILE)")/AppData/Local/Programs/Microsoft VS Code/code.exe" $(HOME)/.local/bin/code

##########################################################
# Wine / Kindle
##########################################################

wine_kindle_fix:
	mkdir -p $(HOME)/.wine/drive_c/users/$(USER)/AppData/Local/Amazon/Kindle

download_kindle:
	wget --trust-server-names https://www.amazon.com/kindlepcdownload/ref=klp_hz_win

winegecko:
	wget http://dl.winehq.org/wine/wine-gecko/2.47.1/wine-gecko-2.47.1-x86.msi
	wine msiexec /i wine-gecko-2.47.1-x86.msi
	wget http://dl.winehq.org/wine/wine-gecko/2.47.1/wine-gecko-2.47.1-x86_64.msi
	wine msiexec /i wine-gecko-2.47.1-x86_64.msi

debian_gecko:
	sudo apt install winbind

wine_kindle:
	wine $(HOME)/.wine/drive_c/Program\ Files\ \(x86\)/Amazon/Kindle/Kindle.exe

##########################################################
# AWS SAM
##########################################################

linux_aws_sam:
	wget https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip
	unzip aws-sam-cli-linux-x86_64.zip -d sam-installation
	sudo ./sam-installation/install

##########################################################
# ASDF
##########################################################

asdf_plugins_install:
	# Read each line from .tool-versions, split into plugin and version.
	# The first column is the plugin name.
	while read plugin version; do \
		asdf plugin add "$$plugin" || true; \
	done < .tool-versions

asdf_install_with_nodejs_mirror:
	env NODEJS_ORG_MIRROR=https://mirrors.dotsrc.org/nodejs/release/ asdf install

##########################################################
# Misc
##########################################################

htoprc_ignore_changes:
	git update-index --assume-unchanged config/htop/htoprc

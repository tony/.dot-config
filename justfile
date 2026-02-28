##########################################################
# justfile — command runner for dotfiles setup tasks
# Converted from Makefile; run `just` to list all recipes
##########################################################

set shell := ["bash", "-cu"]

# ── Variables ──────────────────────────────────────────

dot_config_dir := env("HOME") / ".dot-config"
home           := env("HOME")

pip_packages := "python-language-server virtualenv pipenv tmuxp vcspull dotfiles spotdl ptpython git-sweep"

npm_packages := "npm-check-updates gatsby-cli lerna @angular/cli"

debian_packages := "unzip wget tmux rsync cmake ninja-build cowsay fortune-mod vim-nox universal-ctags silversearcher-ag git tig most entr curl keychain openssh-server htop ccls redis-server libsasl2-dev libxslt1-dev libxmlsec1-dev libxml2-dev libldap2-dev libffi-dev libsqlite3-dev libreadline-dev libbz2-dev build-essential pkg-config libtool m4 automake autoconf zsh"

debian_packages_x11 := "pgadmin3 kitty fonts-noto-cjk xfonts-wqy fonts-cascadia-code rxvt-unicode-256color nitrogen scrot maim slop gammastep"

debian_pyenv_build_pkgs := "make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev libpython3-all-dev"

# ── Default ────────────────────────────────────────────

# List all available recipes
default:
    @just --list

# ══════════════════════════════════════════════════════
# dotfiles group
# ══════════════════════════════════════════════════════

# Symlink dot-config files into $HOME
install: && _install-ssh-config _install-xdg-config
    ln -si {{ dot_config_dir }}/.tmux/ ~
    ln -si ~/.tmux/.tmux.conf ~
    ln -si {{ dot_config_dir }}/.vim/ ~
    ln -si {{ dot_config_dir }}/.fonts/ ~
    ln -si {{ dot_config_dir }}/.gitconfig ~/.gitconfig
    ln -si {{ dot_config_dir }}/.gitignore_global ~/.gitignore_global
    ln -si {{ dot_config_dir }}/.zshrc ~/.zshrc
    ln -si {{ dot_config_dir }}/.zshenv ~/.zshenv
    ln -si {{ dot_config_dir }}/.asdfrc ~/.asdfrc
    ln -si {{ dot_config_dir }}/.tool-versions ~/.tool-versions
    ln -si {{ dot_config_dir }}/.vcspull ~
    ln -si {{ dot_config_dir }}/.vcspull.yaml ~/.vcspull.yaml
    ln -si {{ dot_config_dir }}/.Xresources ~/.Xresources
    ln -si {{ dot_config_dir }}/.ipython ~
    ln -si {{ dot_config_dir }}/.ptpython ~
    ln -si {{ dot_config_dir }}/.tmux/ ~
    ln -si {{ dot_config_dir }}/.tmuxp/ ~
    ln -si {{ dot_config_dir }}/.zsh_plugins.txt ~
    ln -si {{ dot_config_dir }}/.dotfilesrc ~

alias i := install

[private]
_install-ssh-config:
    mkdir -p ~/.ssh
    ln -si {{ dot_config_dir }}/.ssh/config ~/.ssh/config

[private]
_install-xdg-config:
    mkdir -p ~/.config
    ln -si {{ dot_config_dir }}/config/starship.toml ~/.config/starship.toml
    ln -si {{ dot_config_dir }}/config/sheldon/ ~/.config/sheldon

# ══════════════════════════════════════════════════════
# lint group
# ══════════════════════════════════════════════════════

# Run shellcheck on shell scripts in .shell/
lint:
    shellcheck -s sh .shell/**/*.sh

alias l := lint

# Format *.sh/*.zsh files using beautysh
fmt:
    beautysh $(find . \
      -type f \
      -not -path '*/.vim*' \
      -not -path '*/.git*' \
      -not -path '*/.tmux*' \
      -not -path '*/config/base16-shell*' \
      -not -path '*.shell/prompt/git-prompt.sh' \
      | grep -i '.*[.]\(z\)\?sh$\|[.]zsh.*$' 2>/dev/null)

alias f := fmt

# Format config/nvim Lua files with stylua
fmt-lua:
    #!/usr/bin/env bash
    if ! command -v stylua >/dev/null 2>&1; then
        echo "stylua not found. Install stylua to format Lua files." >&2
        exit 1
    fi
    files=$(find config/nvim -type f -name '*.lua')
    if [ -z "$files" ]; then
        echo "No Lua files found under config/nvim"
        exit 0
    fi
    stylua $files

# Run ruff check, ruff format check, and mypy on dot.py
py-check:
    uv run ruff check .
    uv run ruff format --check .
    uv run mypy

alias pc := py-check

# Run pytest with coverage for dot.py
py-test:
    uv run pytest test_dot.py --cov -v

# ══════════════════════════════════════════════════════
# debian group
# ══════════════════════════════════════════════════════

# Install common Debian/Ubuntu packages
debian-packages:
    sudo apt-get update
    sudo apt-get install {{ debian_packages }}

alias deb := debian-packages

# Install extra X11 environment packages
debian-packages-x11:
    sudo apt-get update
    sudo apt-get install {{ debian_packages_x11 }}

# Install system deps needed for pyenv builds
debian-pyenv-packages:
    sudo apt-get update
    sudo apt-get install --no-install-recommends {{ debian_pyenv_build_pkgs }}

# Update apt packages
[confirm]
debian-update:
    sudo apt update && sudo apt upgrade

# Install i3 window manager from sur5r repo
ubuntu-i3:
    sudo /usr/lib/apt/apt-helper download-file https://debian.sur5r.net/i3/pool/main/s/sur5r-keyring/sur5r-keyring_2020.02.03_all.deb keyring.deb \
      SHA256:c5dd35231930e3c8d6a9d9539c846023fe1a08e4b073ef0d2833acd815d80d48
    sudo dpkg -i ./keyring.deb
    echo "deb https://debian.sur5r.net/i3/ $(grep '^DISTRIB_CODENAME=' /etc/lsb-release | cut -f2 -d=) universe" | sudo tee /etc/apt/sources.list.d/sur5r-i3.list
    sudo apt update
    sudo apt install i3

# Install sway and related Wayland packages
ubuntu-sway:
    sudo apt install swayidle swaybg sway-backgrounds sway swaylock wofi

# Disable mpd service on startup
[confirm]
debian-disable-mpd:
    sudo update-rc.d mpd disable
    sudo systemctl disable mpd.socket

# Install clangd-13 and set as default
debian-clangd:
    sudo apt install clangd-13
    sudo update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-13 100

# Install Elasticsearch 7.x from official repo
debian-elasticsearch:
    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
    sudo apt-get install apt-transport-https
    echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
    sudo apt-get update && sudo apt-get install elasticsearch

# Install peek screen recorder (Ubuntu PPA)
ubuntu-peek:
    sudo add-apt-repository ppa:peek-developers/stable
    sudo apt update && sudo apt install peek

# Install latest git from PPA (Ubuntu)
ubuntu-git:
    sudo add-apt-repository ppa:git-core/ppa
    sudo apt update && sudo apt install git

# Install GitHub CLI
gh-cli:
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
    sudo apt-add-repository https://cli.github.com/packages
    sudo apt update
    sudo apt install gh

# Install winbind for Wine gecko
debian-gecko:
    sudo apt install winbind

# ══════════════════════════════════════════════════════
# python group
# ══════════════════════════════════════════════════════

# Download get-pip.py bootstrap script
pip-install:
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py

# Install Python packages via pip (user-level)
pip-install-packages:
    pip install --user -U {{ pip_packages }}

# Uninstall Python packages
[confirm]
pip-uninstall-packages:
    pip uninstall -y {{ pip_packages }}

# Bootstrap Python: get-pip, install, then pyenv deps
debian-python: debian-pyenv-packages
    wget https://bootstrap.pypa.io/get-pip.py
    python3 get-pip.py
    rm get-pip.py

# Install Poetry 1.0.10 and set up completions
poetry-install:
    curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python - --version 1.0.10 --no-modify-path
    ln -sf {{ dot_config_dir }}/.zfunc/ ~
    poetry completions zsh > ~/.zfunc/_poetry
    poetry self update 1.0.10

# ══════════════════════════════════════════════════════
# node group
# ══════════════════════════════════════════════════════

[private]
_yarn-set-prefix:
    yarn config set prefix {{ home }}/.yarn

# Install global Yarn packages
yarn-add-packages: _yarn-set-prefix
    yarn global add {{ npm_packages }}

# Upgrade global Yarn packages
yarn-upgrade-packages: _yarn-set-prefix
    yarn global upgrade {{ npm_packages }}

# Remove global Yarn packages
[confirm]
yarn-remove-packages:
    yarn global remove {{ npm_packages }}

# Uninstall global NPM packages
[confirm]
npm-uninstall-packages:
    sudo npm uninstall -g {{ npm_packages }}
    npm uninstall -g {{ npm_packages }}
    npm uninstall {{ npm_packages }}

# ══════════════════════════════════════════════════════
# rust group
# ══════════════════════════════════════════════════════

# Install Rust CLI tools via cargo
cargo-install:
    cargo install gitui hyperfine dprint

# ══════════════════════════════════════════════════════
# wsl group
# ══════════════════════════════════════════════════════

# Configure WSL2 VcXsrv display export
configure-wsl2-vcxsrv:
    export DISPLAY=$(grep -m 1 nameserver /etc/resolv.conf | awk '{print $2}'):0.0

# Export winget package list to dotfiles
winget-export-packages:
    winget.exe export -o {{ home }}/.dot-config/os/w11/winget-packages.json

# Import winget packages from dotfiles
[confirm]
winget-import-packages:
    winget.exe import -i {{ home }}/.dot-config/os/w11/winget-packages.json

# Create symlinks for Windows executables in WSL
wsl-shortcuts:
    ln -sf $(wslpath 'C:/Windows/System32/wsl.exe') {{ home }}/.local/bin/wsl
    ln -sf $(wslpath 'C:/Windows/System32/wsl.exe') {{ home }}/.local/bin/wsl.exe
    ln -sf $(wslpath "$(wslvar USERPROFILE)"/AppData/Local/Microsoft/WindowsApps/winget.exe) {{ home }}/.local/bin/winget.exe
    ln -sf $(wslpath "$(wslvar USERPROFILE)"/AppData/Local/Microsoft/WindowsApps/winget.exe) {{ home }}/.local/bin/winget
    ln -sf $(wslpath 'C:/Windows/System32/notepad.exe') {{ home }}/.local/bin/notepad.exe
    ln -sf $(wslpath 'C:/Windows/System32/notepad.exe') {{ home }}/.local/bin/notepad
    ln -sf $(wslpath 'C:/Windows/explorer.exe') {{ home }}/.local/bin/explorer.exe
    ln -sf $(wslpath 'C:/Windows/explorer.exe') {{ home }}/.local/bin/explorer
    ln -sf "$(wslpath "$(wslvar USERPROFILE)")/AppData/Local/Programs/Microsoft VS Code/code.exe" {{ home }}/.local/bin/code.exe
    ln -sf "$(wslpath "$(wslvar USERPROFILE)")/AppData/Local/Programs/Microsoft VS Code/code.exe" {{ home }}/.local/bin/code

# ══════════════════════════════════════════════════════
# misc group
# ══════════════════════════════════════════════════════

# Sync VCS repos via vcspull
vcspull:
    vcspull sync libtmux tmuxp libvcs vcspull g gp-libs unihan-db unihan-etl cihai cihai-cli \
                django-slugify-processor django-docutils website

# Update system, pip packages, and Yarn packages
[confirm]
global-update: debian-update pip-install-packages yarn-upgrade-packages

alias up := global-update

# Pull latest for Gatsby sites
update-gatsby-sites:
    pushd ~/work/parataxic.org; git pull --rebase --autostash; popd
    pushd ~/work/develtech; git pull --rebase --autostash; popd
    pushd ~/work/hsk-django; git pull --rebase --autostash; popd

# Test FZF_DEFAULT_COMMAND evaluation
test-fzf-default-command:
    eval ${FZF_DEFAULT_COMMAND}

# Fix dual-boot clock drift (set hardware clock to local time)
[confirm]
fix-linux-time-dualboot:
    timedatectl set-local-rtc 1 --adjust-system-clock

# Install Travis CI CLI gem
travis-cli:
    sudo gem install travis --no-document

# Install Sentry CLI
sentry-cli:
    curl -sL https://sentry.io/get-cli/ | bash

# Install AWS SAM CLI on Linux
linux-aws-sam:
    wget https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip
    unzip aws-sam-cli-linux-x86_64.zip -d sam-installation
    sudo ./sam-installation/install

# Add asdf plugins from .tool-versions
asdf-plugins-install:
    #!/usr/bin/env bash
    while read -r plugin version; do
        asdf plugin add "$plugin" || true
    done < .tool-versions

# Install asdf versions using Node.js mirror
asdf-install-with-nodejs-mirror:
    env NODEJS_ORG_MIRROR=https://mirrors.dotsrc.org/nodejs/release/ asdf install

# Tell git to ignore htoprc changes
htoprc-ignore-changes:
    git update-index --assume-unchanged config/htop/htoprc

# ── Wine / Kindle ─────────────────────────────────────

# Add Wine repository (Ubuntu)
ubuntu-wine:
    sudo dpkg --add-architecture i386
    wget https://dl.winehq.org/wine-builds/Release.key
    sudo apt-key add Release.key
    sudo apt-add-repository 'https://dl.winehq.org/wine-builds/ubuntu/'

# Create Kindle directory structure in Wine prefix
wine-kindle-fix:
    mkdir -p {{ home }}/.wine/drive_c/users/$(whoami)/AppData/Local/Amazon/Kindle

# Download Kindle for PC installer
download-kindle:
    wget --trust-server-names https://www.amazon.com/kindlepcdownload/ref=klp_hz_win

# Install Wine Gecko engine (32-bit and 64-bit)
winegecko:
    wget http://dl.winehq.org/wine/wine-gecko/2.47.1/wine-gecko-2.47.1-x86.msi
    wine msiexec /i wine-gecko-2.47.1-x86.msi
    wget http://dl.winehq.org/wine/wine-gecko/2.47.1/wine-gecko-2.47.1-x86_64.msi
    wine msiexec /i wine-gecko-2.47.1-x86_64.msi

# Launch Kindle via Wine
wine-kindle:
    wine {{ home }}/.wine/drive_c/Program\ Files\ \(x86\)/Amazon/Kindle/Kindle.exe

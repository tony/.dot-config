#!/bin/sh
# Only tested on FreeBSD 11-CURRENT

if [ ! -d $HOME/Downloads ]; then
  mkdir ~/Downloads
fi

if [ ! -f $HOME/Downloads/get-pip.py ]; then
  cd ~/Downloads && fetch https://raw.github.com/pypa/pip/master/contrib/get-pip.py
fi

if [ pkg info git >/dev/null 2>&1 ]; then
  su - root -c "pkg install git"
fi
if [ pkg info python >/dev/null 2>&1 ]; then
  su - root -c "pkg install python"
fi
if [ ! "$(command -v pip)" != "" ]; then
  su - root -c "python $HOME/Downloads/get-pip.py"
fi

if [ python -c "import dotfiles" >/dev/null 2>&1 ]; then
  pip install --user dotfiles
fi
if [ ! -d $HOME/.dot-config ]; then
  git clone --recursive https://github.com/tony/.dot-config ~/.dot-config
fi
ln -sf ~/.dot-config/.dotfilesrc ~/.dotfilesrc

~/.local/bin/dotfiles --sync

ln -sf ~/.vim/.vimrc ~/.vimrc

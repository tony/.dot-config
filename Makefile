DOT_CONFIG_DIR=~/.dot-config

make lint:
	shellcheck -s sh \.shell/**/*.sh

base16-shell:
	if ! [ -d ~/.config/base16-shell ]; then git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell; fi

antigen:
	curl -L git.io/antigen > ${DOT_CONFIG_DIR}/antigen.zsh

pip:
	curl -L https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py
	python /tmp/get-pip.py


vim:
	cd ${DOT_CONFIG_DIR}/.vim && $(MAKE) complete

install:
	$(MAKE) base16-shell
	$(MAKE) antigen
	$(MAKE) vim

	ln -si ${DOT_CONFIG_DIR}/.tmux/ ~/.tmux
	ln -si ~/.tmux/.tmux.conf ~/.tmux.conf
	ln -si ${DOT_CONFIG_DIR}/.vim/ ~/.vim
	ln -si ~/.vim/.vimrc ~/.vimrc
	ln -si ${DOT_CONFIG_DIR}/.fonts/ ~/.fonts
	ln -si ${DOT_CONFIG_DIR}/.gitconfig ~/.gitconfig
	ln -si ${DOT_CONFIG_DIR}/.gitignore_global ~/.gitignore_global
	ln -si ${DOT_CONFIG_DIR}/.zshrc ~/.zshrc
	ln -si ${DOT_CONFIG_DIR}/.vcspull ~/.vcspull
	ln -si ${DOT_CONFIG_DIR}/.vcspull.yaml ~/.vcspull.yaml
	ln -si ${DOT_CONFIG_DIR}/.Xresources ~/.Xresources

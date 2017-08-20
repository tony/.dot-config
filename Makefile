DOT_CONFIG_DIR=~/.dot-config
${DOT_CONFIG_DIR:-$DOT_CONFIG_DIR}

make lint:
	shellcheck -s sh \.shell/**/*.sh

base16-shell:
	git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell

antigen:
	curl -L git.io/antigen > ${DOT_CONFIG_DIR}/antigen.zsh

pip:
	curl -L https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py
	python /tmp/get-pip.py

install:
	$(MAKE) base16-shell
	$(MAKE) antigen

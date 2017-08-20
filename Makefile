make lint:
	shellcheck -s sh \.shell/**/*.sh

base16-shell:
	git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell

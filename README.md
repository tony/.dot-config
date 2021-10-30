# dot-config files

zsh + [zinit] + [starship] + [fzf]

Feel free to copy and paste from here, everything is licensed [MIT].

Powered by antigen.

Just want snippets? Feel free to check out [devel.tech\'s snippets section].

[mit]: http://opensource.org/licenses/MIT
[devel.tech\'s snippets section]: https://devel.tech/snippets/

## Dependencies

- zsh
- curl (for installation)
- git

I keep commonly install packages I use in _bootstrap-\[platform\].sh_.

## Installation

```{.sh}
$ make install
```

## Commands / Aliases

- `update_packages` - Updates debian packages, npm global dependencies, pipx and pip dependencies
- `clear_pyc` - Remove python2/3 cache files recursively
- `clear_empty_dirs` - Removes empty directories recursively

## Nice things

- `FZF_DEFAULT_COMMAND` automatically ignores binary file formats / package directories. vim fuzzy
  file search can be opened anywhere without being overwhelmed by junk files.

## Support

---

Window manager [awesome], [i3]
Terminal multiplexer [tmux] (and [tmuxp] for tmux sessions)
Linux Xsession `.xprofile`, `.Xresources`, `.xsessionrc`
Shell [zsh]
Editor [vim]
Development [ctags], [python cli], [git], [vcspull]
Media [ncmpcpp]
This package [dotfiles] (for this repo), `.tmuxp.yaml`

---

[awesome]: http://awesome.naquadah.org/
[i3]: http://i3wm.org/
[tmux]: http://tmux.sourceforge.net/
[tmuxp]: https://github.com/tony/tmuxp
[zsh]: http://www.zsh.org/
[vim]: http://www.vim.org/
[ctags]: http://ctags.sourceforge.net/
[python cli]: https://docs.python.org/2/using/cmdline.html
[git]: http://git-scm.com/
[vcspull]: https://github.com/tony/vcspull
[ncmpcpp]: http://ncmpcpp.rybczak.net/
[dotfiles]: https://pypi.org/project/dotfiles/

## Structure

---

- [`.zshrc`](.zshrc) [zinit]-based stuff. Uses [starship]
- [`.shell/`](.shell/) Shell plugins depo (via `.sh` scripts)

     - [`.shell/env.d`](.shell/env.d) example: [`env.d/poetry.sh`](.shell/env.d/poetry.sh) checks for poetry and `source`'s it in

          When installing CLI tools, sometimes these are automatically added to
          `.bashrc` / `.zshrc` by installer tools.

          Assuming `.zshrc`, if you have this line:

          `[ -f ~/.poetry/env ] && source $HOME/.poetry/env`

          You can safely replace it with:

          `source ~/.dot-config/.shell/env.d/poetry.sh`

     - [`.shell/vars.d`](.shell/env.d) env variables, e.g. [FZF] ([fzf.vim]'s) [`FZF_DEFAULT_COMMAND`] and + [ignore pattern](.shell/vars.d/ignore.sh] variables
     - [`.shell/paths.d`](.shell/paths.d) Add things like [python site packages](.shell/paths.d/python.sh) / [yarn](.shell/paths.d/yarn.sh) to
       `PATH`

- [`.vim/`](.vim/) See \<<https://github.com/tony/vim-config>\>.
- [`.tmux/`](.tmux/) See \<<https://github.com/tony/tmux-config>\>.
- [`.i3/`](.i3) See \<<https://github.com/tony/i3-config>\>.
- [`.config/awesome/`](.config/awesome/) See \<<https://github.com/tony/.config/awesome>\>
- [`.fonts/`](.fonts/) See \<<https://github.com/tony/dot-fonts>\>.
- [`.tmuxp/`](.tmuxp/) [tmuxp] sessions for common processes. See \<<https://github.con/tony/tmuxp-config>\>
- [`.vcspull.yaml`](.vcspull.yaml) Study and stay up to date with great programming code.
- [`.pythonrc`](.pythonrc) Autocompletion (requires [readline], if your system doesn\'t support it (OSX) try the [stand-alone readline module])
- [`.Xresources`](.Xresources) [rxvt-unicode] settings: [fcitx] input, [molokai] / gruvbox colorscheme / programmer + CJK fonts (see `.fonts`)
- [`.xsessionrc`](.xsessionrc) [Thinkpad Trackpoint config]
- [`.ncmpcpp/`](.ncmpcpp/) FIFO Visualizer
- [`.dotfilesrc`](.dotfilesrc) Ignores `git(1)`-related dotfiles in this project.

---

[starship]: https://starship.rs/
[zinit]: https://github.com/zdharma-continuum/zinit
[fzf]: https://github.com/junegunn/fzf
[`fzf_default_command`]: https://github.com/junegunn/fzf.vim/blob/4145f53/doc/fzf-vim.txt#L115
[fzf.vim]: https://github.com/junegunn/fzf.vim
[tmuxp]: https://github.com/tony/tmuxp
[readline]: https://docs.python.org/2/library/readline.html
[stand-alone readline module]: https://pypi.python.org/pypi/readline
[fcitx]: https://fcitx-im.org/wiki/Fcitx
[molokai]: https://github.com/tomasr/molokai
[thinkpad trackpoint config]: http://www.thinkwiki.org/wiki/How_to_configure_the_TrackPoint

## Notes

### neovim

VIM config is backward compatible. `~/.config/nvim/init.vim` checks and `~/.vim/.vimrc` and
`~/.vimrc` and sources the first it finds.

## Old branch

To see the old codebar (before antigen) see [legacy-2017 branch].

[legacy-2017 branch]: https://github.com/tony/.dot-config/tree/legacy-2017

================
dot-config files
================

Feel free to copy and paste from here, everything is licensed `MIT`_.

Powered by antigen.

Just want snippets? Feel free to check out `devel.tech's snippets section
<https://devel.tech/snippets/>`_.

Dependencies
============

- zsh
- curl (for installation)
- git

I keep commonly install packages I use in  *bootstrap-[platform].sh*.

Installation
============

.. code-block:: sh
   
   $ make install

.. _MIT: http://opensource.org/licenses/MIT

Support
=======

========================  ================================================

Window manager            `awesome`_, `i3`_
Terminal multiplexer      `tmux`_ (and `tmuxp`_ for tmux sessions)
Linux Xsession            ``.xprofile``, ``.Xresources``, ``.xsessionrc``
Shell                     `zsh`_
Editor                    `vim`_
Development               `ctags`_, `python cli`_, `git`_, `vcspull`_
Media                     `ncmpcpp`_
This package              `dotfiles`_ (for this repo), ``.tmuxp.yaml``

========================  ================================================

.. _awesome: http://awesome.naquadah.org/
.. _i3: http://i3wm.org/
.. _tmux: http://tmux.sourceforge.net/
.. _tmuxp: https://github.com/tony/tmuxp
.. _zsh: http://www.zsh.org/
.. _vim: http://www.vim.org/
.. _ctags: http://ctags.sourceforge.net/
.. _python cli: https://docs.python.org/2/using/cmdline.html
.. _git: http://git-scm.com/
.. _vcspull: https://github.com/tony/vcspull
.. _ncmpcpp: http://ncmpcpp.rybczak.net/

Structure
=========

========================  ================================================

``.vim/``                 See <https://github.com/tony/vim-config>.
``.tmux/``                See <https://github.com/tony/tmux-config>.
``.i3/``                  See <https://github.com/tony/i3-config>.
``.config/awesome/``      See <https://github.com/tony/.config/awesome>
``.fonts/``               See <https://github.com/tony/dot-fonts>.
``.tmuxp/``               `tmuxp`_ sessions for common processes.
                          See <https://github.con/tony/tmuxp-config>
``.vcspull.yaml``         Study and stay up to date with great programming
                          code.
``.pythonrc``             Autocompletion (requires `readline`_, if your
                          system doesn't support it (OSX) try the
                          `stand-alone readline module`_)
``.zshrc``                - `oh-my-zsh`_.
                          - if exists, prepares shell for: `pyenv`_,
                            `rbenv`_, `perlbrew`_, `virtualenv`_,
                            `virtualenvwrapper`_ and prepares shell for
                            it.
                          - checks for ``.profile`` and sources it.
                          - add npm, node to path (``/usr/local/``
                            installation)
                          - add ``$HOME/bin`` to front of path
``.Xresources``           - `rxvt-unicode` settings:

                            - `fcitx`_ input
                            - `molokai`_ colorscheme
                            - programmer + CJK fonts (see ``.fonts``)
``.xsessionrc``           `Thinkpad Trackpoint config`_
``.ctags``
``.ncmpcpp``              FIFO Visualizer
``.dotfilesrc``           Ignores ``git(1)``-related dotfiles in this
                          project.
========================  ================================================


.. _oh-my-zsh: https://github.com/robbyrussell/oh-my-zsh
.. _pyenv: https://github.com/yyuu/pyenv
.. _rbenv: https://github.com/sstephenson/rbenv
.. _virtualenv: http://www.virtualenv.org/en/latest/
.. _virtualenvwrapper: http://virtualenvwrapper.readthedocs.org/en/latest/
.. _perlbrew: http://perlbrew.pl/
.. _rxvt-unicode: http://software.schmorp.de/pkg/rxvt-unicode.html
.. _fcitx: https://fcitx-im.org/wiki/Fcitx
.. _molokai: https://github.com/tomasr/molokai
.. _CJK: http://en.wikipedia.org/wiki/CJK_characters
.. _readline: https://docs.python.org/2/library/readline.html
.. _stand-alone readline module: https://pypi.python.org/pypi/readline
.. _Thinkpad Trackpoint config: http://www.thinkwiki.org/wiki/How_to_configure_the_TrackPoint

Notes
=====

neovim
------

VIM config is backward compatible.  ``~/.config/nvim/init.vim`` checks and
``~/.vim/.vimrc`` and ``~/.vimrc`` and sources the first it finds.

Old branch
==========

To see the old codebar (before antigen) see `legacy-2017 branch
<https://github.com/tony/.dot-config/tree/legacy-2017>`_.

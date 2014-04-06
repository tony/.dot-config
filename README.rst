dot-config files
================

System: Debian Jessie

This dot configuration can serve as example of a central repository for
settings of CLI based up.

Configurations
--------------

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

Cloning
-------

.. code-block:: bash

    $ git clone --recursive git@github.com:tony/.dot-config.git ~/.dot-config

Synchronizing dot files
-----------------------

``.dotfilesrc`` is included for support with `dotfiles`_.

Install via `pip`_ (`pip installation instructions`_)

.. _pip: http://www.pip-installer.org/en/latest/
.. _pip installation instructions: http://www.pip-installer.org/en/latest/installing.html
.. _dotfiles: https://github.com/jbernard/dotfiles

License
-------

`MIT License <http://opensource.org/licenses/MIT>`_
